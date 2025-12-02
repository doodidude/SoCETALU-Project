//top.sv
module top (
  hz100, 
  reset,
  pb,
  left, 
  right,
  ss7, 
  ss6, 
  ss5, 
  ss4, 
  ss3, 
  ss2, 
  ss1, 
  ss0,
  red, 
  green, 
  blue,
  txdata,
  rxdata,
  txclk, 
  rxclk,
  txready, 
  rxready
);

  input hz100;
  input reset;
  input [20:0] pb;
  output [7:0] left;
  output [7:0] right;
  output [7:0] ss7;
  output [7:0] ss6;
  output [7:0] ss5;
  output [7:0] ss4;
  output [7:0] ss3;
  output [7:0] ss2;
  output [7:0] ss1;
  output [7:0] ss0;
  output red;
  output green;
  output blue;
  output [7:0] txdata;
  input [7:0] rxdata;
  output txclk;
  output rxclk;
  input txready;
  input rxready;

  // Internal signals
  reg pb0_prev, pb0_sync;
  reg pb1_prev, pb1_sync;
  reg equal_prev;
  reg [7:0] valueA, valueB;
  reg [15:0] final_output;
  
  wire pulse_0, pulse_1;
  wire shift_enable, shift_data;
  wire equal_pressed;
  wire [7:0] shift_reg_out;
  wire [3:0] opcode;
  wire [15:0] alu_result;

  // Opcode from push buttons
  assign opcode = {pb[7], pb[6], pb[3], pb[2]};

  // Button synchronization for pb[0]
  always @(posedge hz100) begin
    if (pb[19]) begin
      pb0_prev <= 0;
      pb0_sync <= 0;
    end else begin
      pb0_prev <= pb0_sync;
      pb0_sync <= pb[0];
    end
  end
  assign pulse_0 = (pb0_prev == 0) && (pb0_sync == 1);

  // Button synchronization for pb[1]
  always @(posedge hz100) begin
    if (pb[20]) begin
      pb1_prev <= 0;
      pb1_sync <= 0;
    end else begin
      pb1_prev <= pb1_sync;
      pb1_sync <= pb[1];
    end
  end
  assign pulse_1 = (pb1_prev == 0) && (pb1_sync == 1);

  // Equal button edge detection
  always @(posedge hz100) begin
    if (pb[19])
      equal_prev <= 0;
    else
      equal_prev <= pb[16];
  end
  assign equal_pressed = pb[16] & ~equal_prev;

  assign shift_enable = pulse_0 || pulse_1;
  assign shift_data = pulse_1;

  // Shift register instantiation
  shift_reg in (
    .d(shift_data),
    .clk(hz100),
    .en(shift_enable),
    .dir(pb[4]),
    .rstn(~pb[18]),
    .out(shift_reg_out)
  );

  // Value storage for A and B
  always @(posedge hz100 or posedge pb[19]) begin
    if (pb[19]) begin
      valueA <= 8'b0;
      valueB <= 8'b0;
    end else begin
      if (pb[10])
        valueA <= shift_reg_out;
      if (pb[11])
        valueB <= shift_reg_out;
    end
  end

  // ALU instantiation
  op_code alu (
    .valA(valueA),
    .valB(valueB),
    .opcode(opcode),
    .result(alu_result)
  );

  // Register ALU output when equal is pressed
  always @(posedge hz100 or posedge pb[19]) begin
    if (pb[19])
      final_output <= 16'b0;
    else if (equal_pressed)
      final_output <= alu_result;
  end

  // Display shift register output on ss0 and ss1
  ssdec decoder_ss0 (
    .in(shift_reg_out[3:0]),
    .enable(1'b1),
    .out(ss0)
  );

  ssdec decoder_ss1 (
    .in(shift_reg_out[7:4]),
    .enable(1'b1),
    .out(ss1)
  );

  // Display valueA on ss6 and ss7
  ssdec decoder_ss6 (
    .in(valueA[3:0]),
    .enable(1'b1),
    .out(ss6)
  );

  ssdec decoder_ss7 (
    .in(valueA[7:4]),
    .enable(1'b1),
    .out(ss7)
  );

  // Display valueB on ss4 and ss5
  ssdec decoder_ss4 (
    .in(valueB[3:0]),
    .enable(1'b1),
    .out(ss4)
  );

  ssdec decoder_ss5 (
    .in(valueB[7:4]),
    .enable(1'b1),
    .out(ss5)
  );

  // Display ALU result on ss2 and ss3
  ssdec decoder_ss2 (
    .in(final_output[3:0]),
    .enable(1'b1),
    .out(ss2)
  );

  ssdec decoder_ss3 (
    .in(final_output[7:4]),
    .enable(1'b1),
    .out(ss3)
  );

endmodule

//shift_reg.sv

module shift_reg (
  d,
  clk,
  en,
  dir,
  rstn,
  out
);

  parameter MSB = 8;
  
  input d;
  input clk;
  input en;
  input dir;
  input rstn;
  output [MSB-1:0] out;

  reg [MSB-1:0] shift_out;

  always @(posedge clk or negedge rstn) begin
    if (!rstn)
      shift_out <= 0;
    else begin
      if (en)
        case (dir)
          0: shift_out <= {shift_out[MSB-2:0], d};
          1: shift_out <= {d, shift_out[MSB-1:1]};
        endcase
      else
        shift_out <= shift_out;
    end
  end

  assign out = shift_out;

endmodule

//ssdec.sv

module ssdec (
  in,
  enable,
  out
);

  input [3:0] in;
  input enable;
  output [7:0] out;
  
  reg [7:0] out;

  always @(*) begin
    if (enable) begin
      case(in)
        4'h0: out = 8'b00111111;
        4'h1: out = 8'b00000110;
        4'h2: out = 8'b01011011;
        4'h3: out = 8'b01001111;
        4'h4: out = 8'b01100110;
        4'h5: out = 8'b01101101;
        4'h6: out = 8'b01111101;
        4'h7: out = 8'b00000111;
        4'h8: out = 8'b01111111;
        4'h9: out = 8'b01100111;
        4'ha: out = 8'b01110111;
        4'hb: out = 8'b01111100;
        4'hc: out = 8'b00111001;
        4'hd: out = 8'b01011110;
        4'he: out = 8'b01111001;
        4'hf: out = 8'b01110001;
        default: out = 8'b00000000;
      endcase
    end else begin
      out = 8'b00000000;
    end
  end

endmodule

//op_code.sv

module op_code (
  valA,
  valB,
  opcode,
  result
);

  input [7:0] valA;
  input [7:0] valB;
  input [3:0] opcode;
  output [15:0] result;
  
  reg [15:0] result;
  reg [15:0] a_ext;
  reg [15:0] b_ext;
  reg [15:0] mul_result;
  
  always @(*) begin
    a_ext = {8'b0, valA};
    b_ext = {8'b0, valB};
    
    // Simple multiplication using nested conditionals
    mul_result = 0;
    if (valA[0]) mul_result = mul_result + b_ext;
    if (valA[1]) mul_result = mul_result + (b_ext << 1);
    if (valA[2]) mul_result = mul_result + (b_ext << 2);
    if (valA[3]) mul_result = mul_result + (b_ext << 3);
    if (valA[4]) mul_result = mul_result + (b_ext << 4);
    if (valA[5]) mul_result = mul_result + (b_ext << 5);
    if (valA[6]) mul_result = mul_result + (b_ext << 6);
    if (valA[7]) mul_result = mul_result + (b_ext << 7);
    
    case(opcode)
      4'b0001: result = a_ext + b_ext;        // ADD
      4'b0010: result = a_ext - b_ext;        // SUB
      4'b0011: begin                          // DIV
        if (valB != 0)
          result = a_ext / b_ext;
        else
          result = 16'b0;
      end
      4'b0100: result = mul_result;           // MUL
      default: result = 16'b0;
    endcase
  end
  
endmodule
