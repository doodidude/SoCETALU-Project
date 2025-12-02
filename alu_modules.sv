//top.sv

`default_nettype none

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
  logic [7:0] valueA, valueB;
  logic [7:0] shift_reg_out;
  logic shift_enable, shift_data;

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
  shift_reg #(.MSB(8)) in (
    .clk(hz100), 
    .rstn(~pb[18]), 
    .en(shift_enable), 
    .d(shift_data), 
    .dir(pb[2]), 
    .out(shift_reg_out)
  );
  
  // Display shift register output on ss0 and ss1
  ssdec decoder_for_ss0 (
    .out(ss0),
    .in(shift_reg_out[3:0]),
    .enable(1'b1)
  );

  ssdec decoder_for_ss1 (
    .out(ss1),
    .in(shift_reg_out[7:4]),
    .enable(1'b1)
  ); 
  
  // Display valueA on ss6 and ss7
  ssdec decoder_for_ss6 (
    .out(ss6),
    .in(valueA[3:0]),
    .enable(1'b1)
  );
  
  ssdec decoder_for_ss7 (
    .out(ss7),
    .in(valueA[7:4]),
    .enable(1'b1)
  ); 
  
  // Display valueB on ss4 and ss5
  ssdec decoder_for_ss4 (
    .out(ss4),
    .in(valueB[3:0]),
    .enable(1'b1)
  );
  
  ssdec decoder_for_ss5 (
    .out(ss5),
    .in(valueB[7:4]),
    .enable(1'b1)
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

