`default_nettype none
// Empty top module

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

  logic pb0_prev;
  logic pulse_0;

  always_ff @(posedge hz100 or negedge reset) begin
    if (!reset)
    pb0_prev <= 0; 
    else 
    pb0_prev <= pb[0];
  end
  assign pulse_0 = (pb0_prev == 0) && (pb[0] == 1);

  logic pb1_prev;
  logic pulse_1;

  always_ff @(posedge hz100 or negedge reset) begin
    if (!reset)
    pb0_prev <= 0; 
    else 
    pb1_prev <= pb[1];
  end
  assign pulse_1 = (pb1_prev == 0) && (pb[1] == 1);

  logic shift_enable;
  logic shift_data;

  assign shift_enable = pulse_0 || pulse_1;
  assign shift_data   = pulse_1;
  
  shift_reg #(.MSB(8)) in (.clk(hz100), .rstn(reset), .en(shift_enable), .d(shift_data), .dir(pb[2]), .out(left));

endmodule

module shift_reg  #(parameter MSB) (  input d,                      // Declare input for data to the first flop in the shift register
                                        input clk,                    // Declare input for clock to all flops in the shift register
                                        input en,                     // Declare input for enable to switch the shift register on/off
                                        input dir,                    // Declare input to shift in either left or right direction
                                        input rstn,                   // Declare input to reset the register to a default value
                                        output logic [MSB-1:0] out);    // Declare output to read out the current value of all flops in this register

   always_ff @ (posedge clk or negedge rstn)
      if (!rstn)
         out <= 0;
      else begin
         if (en)
            case (dir)
               0 :  out <= {out[MSB-2:0], d};
               1 :  out <= {d, out[MSB-1:1]};
            endcase
         else
            out <= out;
      end
endmodule

module ssdec(
    output logic [6:0] out,
    input logic [3:0] in,
    input logic enable
);

logic [6:0] temp;
assign temp = (in == 4'h0) ? 7'b0111111:
                (in == 4'h1) ? 7'b0000110:
                (in == 4'h2) ? 7'b1011011:
                (in == 4'h3) ? 7'b1001111:
                (in == 4'h4) ? 7'b1100110:
                (in == 4'h5) ? 7'b1101101:
                (in == 4'h6) ? 7'b1111101:
                (in == 4'h7) ? 7'b0000111:
                (in == 4'h8) ? 7'b1111111:
                (in == 4'h9) ? 7'b1101111:
                (in == 4'hA) ? 7'b1110111:
                (in == 4'hB) ? 7'b1111100:
                (in == 4'hC) ? 7'b0111001:
                (in == 4'hD) ? 7'b1011110:
                (in == 4'hE) ? 7'b1111001:
                (in == 4'hF) ? 7'b1110001: 7'b0000000;  

assign out = enable ? temp: 7'b000000;
endmodule
