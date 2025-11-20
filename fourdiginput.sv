module button_input (
    input  logic clk,
    input  logic rst_n,
    input  logic [9:0]  pb,        
    output logic [13:0] number     
);
    logic [9:0] pb_prev;           
    logic [9:0] pb_pressed;        
    logic [3:0] digit;             
    logic digit_count;      
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pb_prev <= 10'b0;
        else
            pb_prev <= pb;
    end
    
    assign pb_pressed = pb & ~pb_prev; 
    
    always_comb begin
        digit = 4'd0;
        
        for (int i = 0; i < 10; i++) begin
            if (pb_pressed[i]) begin
                digit = i[3:0];
            end
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            number <= 14'd0;
            digit_count <= 0;
        end else if (digit_count < 4) begin
            number <= number * 10 + digit;
            digit_count <= digit_count + 1;
        end
    end
endmodule





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

  // Your code goes here...
  logic [13:0] captured_number;
  
  // Instantiate the button_input module
  button_input btn_in (
    .clk(hz100),                    // Connect 100Hz clock
    .rst_n(~reset),                 // Connect reset (inverted if reset is active high)
    .pb(pb[9:0]),                   // Connect first 10 pushbuttons
    .number(captured_number)        // Output: the accumulated number
  );
  
endmodule

// Add more modules down here...
// Code your design here

module button_input (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [9:0]  pb,        
    output logic [13:0] number
);

    logic [9:0] pb_prev;           
    logic [9:0] pb_pressed;        
    logic [3:0] digit;             
    int digit_count;      
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pb_prev <= 10'b0;
        else
            pb_prev <= pb;
    end
    
    assign pb_pressed = pb & ~pb_prev; 
    
    always_comb begin
        digit = 4'd0;
        
        for (int i = 0; i < 10; i++) begin
            if (pb_pressed[i]) begin
                digit = i[3:0];
            end
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            number <= 14'd0;
            digit_count <= 0;
        end else if (digit_count < 4) begin
            //number <= number * 10 + digit;
            number <= number * 14'd10 + {10'd0, digit};
            digit_count <= digit_count + 1;
        end
    end
endmodule

