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
  logic [15:0] valueA, valueB;
  logic [15:0] next_A, next_B;

// Update Input value A and input Value B
always_ff @(posedge hz100 or posedge pb[19]) begin
    if (pb[19]) begin
        valueA <= 0;
        valueB <= 0;
    end else begin
        //if (pb[10])
            valueA <= next_A; //shift_reg_out;   // save current shift reg to A
        //if (pb[11])
            valueB <= next_B; //shift_reg_out;   // save current shift reg to B
    end 
end
always_comb begin
next_A = valueA;
next_B = valueB;
if (pb[10]) begin
next_A = shift_reg_out;
end else if (pb[11]) begin
next_B = shift_reg_out;
end else begin
next_A = valueA;
next_B = valueB;
end 
end
  
 //Tracking change in the input so if held down it doesn't repeat input
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
    if (pb[19]) begin 
    pb1_prev <= 0; 
    pb1_sync <= 0;
    end 
    else begin 
    pb1_prev <= pb1_sync;
    pb1_sync <= pb[1];
    end
  end 
  // End of Input tracking
 
  assign pulse_1 = (pb1_prev == 0) && (pb1_sync == 1); 
  logic[15:0] shift_reg_out;  

  logic shift_enable;
  logic shift_data;

  assign shift_enable = pulse_0 || pulse_1;
  assign shift_data   = pulse_1;
  // End of input timing logic
  
  
  // Call of Shift Register Module
  shift_reg #(.MSB(16)) in (.clk(hz100), .rstn(~pb[18]), .en(shift_enable), .d(shift_data), .dir(pb[2]), .out(shift_reg_out));

  logic [3:0] ssin0;
  logic [3:0] ssin1;
  logic [3:0] ssin2;
  logic [3:0] ssin3;

always_comb begin 
  if (pb[10]) begin
    // ssin0 gets the 4 least significant bits (0 to 3)
    ssin0 = valueA[3:0];
    // ssin1 gets the next 4 bits (4 to 7)
    ssin1 = valueA[7:4];
    // ssin2 gets the next 4 bits (8 to 11)
    ssin2 = valueA[11:8];
    // ssin3 gets the 4 most significant bits (12 to 15)
    ssin3 = valueA[15:12];
  end else if (pb[11]) begin 
    ssin0 = valueB[3:0];
    ssin1 = valueB[7:4];
    ssin2 = valueB[11:8];
    ssin3 = valueB[15:12];
    end else begin
    ssin0 = 0; 
    ssin1 = 0;
    ssin2 = 0;
    ssin3 = 0;
  end // pb[16] for final output 
end 

ssdec sd0 (.in(ssin0), .enable(1'b1), .out(ss0)); 
ssdec sd1 (.in(ssin1), .enable(1'b1), .out(ss1)); 
ssdec sd2 (.in(ssin2), .enable(1'b1), .out(ss2)); 
ssdec sd3 (.in(ssin3), .enable(1'b1), .out(ss3));

endmodule


//SHIFT REG MODULE
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

// SSDEC Module 
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
