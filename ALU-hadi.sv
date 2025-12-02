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
  reg [15:0] valueA, valueB;
  reg [31:0] final_output;
  
  wire pulse_0, pulse_1;
  wire shift_enable, shift_data;
  wire equal_pressed;
  wire [15:0] shift_reg_out; 
  wire [3:0] opcode;
  wire [31:0] alu_result;
  logic [31:0] ssout;
  logic [31:0] next_ssout; 

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
      // FIXED: Width match 16 bits
      valueA <= 16'b0;
      valueB <= 16'b0;
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
      final_output <= 32'b0;
    else if (equal_pressed)
      final_output <= alu_result;
  end

  // HADI ADD 
  always_ff @(posedge hz100 or posedge pb[19]) begin
    if (pb[19]) begin 
      ssout <= 0; 
    end else begin
      ssout <= next_ssout; 
    end 
  end 

  always_comb begin 
    if (pb[10]) begin
      next_ssout = {16'b0, valueA}; 
    end else if (pb[11]) begin 
      next_ssout = {16'b0, valueB}; 
    end else if (pb[16]) begin
      next_ssout = alu_result; 
    end else begin 
    next_ssout = ssout;
    end// pb[16] for final output 
  end 

  ssdec sd0 (.in(ssout[3:0]), .enable(1'b1), .out(ss0)); 
  ssdec sd1 (.in(ssout[7:4]), .enable(1'b1), .out(ss1)); 
  ssdec sd2 (.in(ssout[11:8]), .enable(1'b1), .out(ss2)); 
  ssdec sd3 (.in(ssout[15:12]), .enable(1'b1), .out(ss3));
  ssdec sd4 (.in(ssout[19:16]), .enable(1'b1), .out(ss4)); 
  ssdec sd5 (.in(ssout[23:20]), .enable(1'b1), .out(ss5)); 
  ssdec sd6 (.in(ssout[27:24]), .enable(1'b1), .out(ss6)); 
  ssdec sd7 (.in(ssout[31:28]), .enable(1'b1), .out(ss7));

// END HADI ADD 

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

  parameter MSB = 16;
  
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

  input [15:0] valA;
  input [15:0] valB;
  input [3:0] opcode;
  output [31:0] result;
  
  reg [31:0] result; 
  reg [31:0] a_ext;
  reg [31:0] b_ext;
  reg [31:0] mul_result;
  
  always @(*) begin
    a_ext = {16'b0, valA};
    b_ext = {16'b0, valB};
    
    // Simple multiplication using nested conditionals
    mul_result = 0;
    if (valA[8])  mul_result = mul_result + (b_ext << 8);
    if (valA[9])  mul_result = mul_result + (b_ext << 9);
    if (valA[10]) mul_result = mul_result + (b_ext << 10);
    if (valA[11]) mul_result = mul_result + (b_ext << 11);
    if (valA[12]) mul_result = mul_result + (b_ext << 12);
    if (valA[13]) mul_result = mul_result + (b_ext << 13);
    if (valA[14]) mul_result = mul_result + (b_ext << 14);
    if (valA[15]) mul_result = mul_result + (b_ext << 15);
    
    case(opcode)
      4'b0001: result = a_ext + b_ext;        // ADD
      4'b0010: result = a_ext - b_ext;        // SUB
      4'b0011: begin                          // DIV
        if (valB != 0)
          result = a_ext / b_ext;
        else
          result = 32'b0;
      end
      4'b0100: result = mul_result;           // MUL
      default: result = 32'b0;
    endcase
  end
  
endmodule
