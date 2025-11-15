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
  logic pb0_sync; 
  logic pulse_0;
  // Franklin Added
  logic [7:0] valueA, valueB;

always_ff @(posedge hz100 or posedge pb[19]) begin
    if (pb[19]) begin
        valueA <= 0;
        valueB <= 0;
    end else begin
        if (pulse_0)
            valueA <= shift_reg_out;   // save current shift reg to A
        if (pulse_1)
            valueB <= shift_reg_out;   // save current shift reg to B
    end
end
//
 
  always_ff @(posedge hz100) begin
    if (pb[19]) begin 
    pb0_prev <= 0; 
    pb0_sync <= 0;
    end 
    else begin 
    pb0_prev <= pb0_sync;
    pb0_sync <= pb[0];
    end
  end 

  assign pulse_0 = (pb0_prev == 0) && (pb0_sync == 1);
 
  logic pb1_prev;
  logic pb1_sync; 
  logic pulse_1;

  always_ff @(posedge hz100) begin
    if (pb[20]) begin 
    pb1_prev <= 0; 
    pb1_sync <= 0;
    end 
    else begin 
    pb1_prev <= pb1_sync;
    pb1_sync <= pb[1];
    end
  end 

  assign pulse_1 = (pb1_prev == 0) && (pb1_sync == 1); 
  logic[7:0] shift_reg_out;  

  logic shift_enable;
  logic shift_data;

  assign shift_enable = pulse_0 || pulse_1;
  assign shift_data   = pulse_1;
  
  shift_reg #(.MSB(8)) in (.clk(hz100), .rstn(~pb[19]), .en(shift_enable), .d(shift_data), .dir(pb[2]), .out(shift_reg_out));

  // Connects LOW 4 bits (left[3:0]) to display ss0
  ssdec decoder_for_ss0 (
      .out(ss0),        // Connect the 7-bit output to the 'ss0' display port
      .in(shift_reg_out[3:0]),   // Connect the 4-bit input to the LOW 4 bits of 'left'
      .enable(1'b1)     // Turn the display on
  );

  // Connects HIGH 4 bits (left[7:4]) to display ss1
  ssdec decoder_for_ss1 (
      .out(ss1),        // Connect the 7-bit output to the 'ss1' display port
      .in(shift_reg_out[7:4]),   // Connect the 4-bit input to the HIGH 4 bits of 'left'
      .enable(1'b1)     // Turn the display on
      ); 

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
  input logic [3:0]in,
  input logic enable,
  output logic [7:0]out
);

logic [6:0] SEG7 [15:0];

assign SEG7[4'h0] = 7'b0111111;
assign SEG7[4'h1] = 7'b0000110;
assign SEG7[4'h2] = 7'b1011011;
assign SEG7[4'h3] = 7'b1001111;
assign SEG7[4'h4] = 7'b1100110;
assign SEG7[4'h5] = 7'b1101101;
assign SEG7[4'h6] = 7'b1111101;
assign SEG7[4'h7] = 7'b0000111;
assign SEG7[4'h8] = 7'b1111111;
assign SEG7[4'h9] = 7'b1100111;
assign SEG7[4'ha] = 7'b1110111;
assign SEG7[4'hb] = 7'b1111100;
assign SEG7[4'hc] = 7'b0111001;
assign SEG7[4'hd] = 7'b1011110;
assign SEG7[4'he] = 7'b1111001;
assign SEG7[4'hf] = 7'b1110001;

assign out = enable ? {1'b0, SEG7[in]}: 8'b00000000;


endmodule
