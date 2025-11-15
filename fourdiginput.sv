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