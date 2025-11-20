localparam OPCODE_WIDTH = 4;

//def fsm states for alu
typedef enum logic [OPCODE_WIDTH-1:0] {
  ADD = 4'b0001,//1
  SUB = 4'b0010,//2
  DIV = 4'b0011,//3
  MUL = 4'b0100//4
} alu_opcode_t;

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


//instantation
logic equal;
logic [3:0] op;
logic [31:0] final_output;
logic [31:0] alu_result;
logic equal_prev;
logic equal_pressed;

assign equal = pb[16];
assign op = {pb[7], pb[6], pb[3], pb[2]};

//check if pb 16 pressed
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    equal_prev <= 1'b0;
  else
    equal_prev <= equal;
end

assign equal_pressed = equal & ~equal_prev;

opcode comp (
  .valA(valA),
  .valB(valB),
  .opcode(alu_opcode_t'(op)),  
  .result(alu_result)
);

//register the output when equal is pressed
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    final_output <= 32'b0;
  else if (equal_pressed)
    final_output <= alu_result;
end