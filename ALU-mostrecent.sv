//top.sv

`default_nettype none

localparam OPCODE_WIDTH = 4;

  typedef enum logic [OPCODE_WIDTH-1:0] {
  ADD = 4'b0001,//1
  SUB = 4'b0010,//2
  DIV = 4'b0011,//3
  MUL = 4'b0100//4
  } alu_opcode_t;

module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

  logic pb0_prev, pb0_sync, pulse_0;
  logic pb1_prev, pb1_sync, pulse_1;
  logic [15:0] valueA, valueB;
  logic [15:0] shift_reg_out;
  logic shift_enable, shift_data;
  logic [15:0] ssout;
  logic [15:0] next_ssout; 
  logic equal;
  logic [3:0] op;
  logic [31:0] final_output;
  logic [31:0] alu_result;
  logic equal_prev;
  logic equal_pressed;

  // Update Input value A and input Value B
  always_ff @(posedge hz100 or posedge pb[19]) begin
    if (pb[19]) begin
      valueA <= 0;
      valueB <= 0;
    end else begin
      if (pb[10])
        valueA <= shift_reg_out;   // save current shift reg to A
      if (pb[11])
        valueB <= shift_reg_out;   // save current shift reg to B
    end
  end

  // Tracking change in pb[0] input
  always_ff @(posedge hz100) begin
    if (pb[19]) begin 
      pb0_prev <= 0; 
      pb0_sync <= 0;
    end else begin 
      pb0_prev <= pb0_sync;
      pb0_sync <= pb[0];
    end
  end 

  assign pulse_0 = (pb0_prev == 0) && (pb0_sync == 1);
 
  // Tracking change in pb[1] input
  always_ff @(posedge hz100) begin
    if (pb[20]) begin 
      pb1_prev <= 0; 
      pb1_sync <= 0;
    end else begin 
      pb1_prev <= pb1_sync;
      pb1_sync <= pb[1];
    end
  end 

  assign pulse_1 = (pb1_prev == 0) && (pb1_sync == 1); 

  assign shift_enable = pulse_0 || pulse_1;
  assign shift_data   = pulse_1;
  
  // Instantiate Shift Register Module
  shift_reg #(.MSB(16)) in (
    .clk(hz100), 
    .rstn(~pb[18]), 
    .en(shift_enable), 
    .d(shift_data), 
    .dir(pb[2]), 
    .out(shift_reg_out)
  );
  
  assign equal = pb[16];
  assign op = {pb[7], pb[6], pb[3], pb[2]};

  //check if pb 16 pressed
  always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
      equal_prev <= 1'b0;
    end else begin 
      equal_prev <= equal;
    end 
  end 

  assign equal_pressed = equal & ~equal_prev;

  opcode comp (.valA(valA), .valB(valB), .opcode(alu_opcode_t'(op)),   .result(alu_result));

  //register the output when equal is pressed
  always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
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
      next_ssout = valueA; 
    end else if (pb[11]) begin 
      next_ssout = valueB; 
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

`default_nettype none

module ssdec (
  input logic [3:0] in,
  input logic enable,
  output logic [7:0] out
);

  always_comb begin
    case(in)
      4'h0: out = enable ? 8'b00111111 : 8'b00000000;
      4'h1: out = enable ? 8'b00000110 : 8'b00000000;
      4'h2: out = enable ? 8'b01011011 : 8'b00000000;
      4'h3: out = enable ? 8'b01001111 : 8'b00000000;
      4'h4: out = enable ? 8'b01100110 : 8'b00000000;
      4'h5: out = enable ? 8'b01101101 : 8'b00000000;
      4'h6: out = enable ? 8'b01111101 : 8'b00000000;
      4'h7: out = enable ? 8'b00000111 : 8'b00000000;
      4'h8: out = enable ? 8'b01111111 : 8'b00000000;
      4'h9: out = enable ? 8'b01100111 : 8'b00000000;
      4'ha: out = enable ? 8'b01110111 : 8'b00000000;
      4'hb: out = enable ? 8'b01111100 : 8'b00000000;
      4'hc: out = enable ? 8'b00111001 : 8'b00000000;
      4'hd: out = enable ? 8'b01011110 : 8'b00000000;
      4'he: out = enable ? 8'b01111001 : 8'b00000000;
      4'hf: out = enable ? 8'b01110001 : 8'b00000000;
      default: out = 8'b00000000;
    endcase
  end

endmodule

module opcode(
  input  logic [15:0] valA,
  input  logic [15:0] valB,
  input  alu_opcode_t opcode,  
  output logic [31:0] result
);
  always_comb begin
    case(opcode)
      ADD: begin
        result = valA + valB;
      end
      SUB: begin
        result = valA - valB;
      end
      DIV: begin
        result = valA / valB;
      end
      MUL: begin
        result = valA * valB;  
      end
      default: begin
        result = 32'b0;  
      end
    endcase
  end
endmodule
