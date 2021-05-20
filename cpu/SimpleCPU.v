`timescale 1ns / 1ps
module SimpleCPU(clk, rst, data_fromRAM, wrEn, addr_toRAM, data_toRAM, pCounter);
 
parameter SIZE = 10;

input clk, rst;
input wire [15:0] data_fromRAM;
output reg wrEn;
output reg [SIZE-1:0] addr_toRAM;
output reg [15:0] data_toRAM;
output reg [SIZE-1:0] pCounter;


// internal signals
reg [ 2:0] opcode, opcodeNext;
reg [12:0] operand1, operand1Next;
reg [SIZE-1:0] /*pCounter,*/ pCounterNext;
reg [15:0] num1,  num1Next;
reg [ 3:0] stateNext;
reg [ 3:0] state;
reg [15:0] W, starA;
reg [ 15:0] WNext, starANext ;

always @(posedge clk)begin
	state    <= #1 stateNext;
	pCounter <= #1 pCounterNext;
	opcode   <= #1 opcodeNext;
	operand1 <= #1 operand1Next;
	num1     <= #1 num1Next;
	W        <= #1 WNext;
	starA    <= #1 starANext;
end

always @*begin
	stateNext    = state;
	pCounterNext = pCounter;
	opcodeNext   = opcode;
	operand1Next = operand1;
	num1Next     = num1;
	WNext        = W;
	addr_toRAM   = 0;
	wrEn         = 0;
	data_toRAM   = 0;
if(rst)
	begin
	stateNext    = 0;
	pCounterNext = 0;
	opcodeNext   = 0;
	operand1Next = 0;
	num1Next     = 0;
	WNext        = W;
	addr_toRAM   = 0;
	wrEn         = 0;
	data_toRAM   = 0;
	starANext    = 0;
	end
else 
	case(state)                       
		0: begin											// take instruction
			pCounterNext = pCounter;
			opcodeNext   = opcode;
			operand1Next = 0;
			addr_toRAM   = pCounter;
			num1Next     = 0;
			WNext        = W;
			wrEn         = 0;
			data_toRAM   = 0;
			stateNext    = 1;
		end 
		1:begin // take A adress 
			pCounterNext = pCounter;
			opcodeNext   = data_fromRAM[15:13];//data_fromRAM[15:13];
			operand1Next = data_fromRAM[12:0];
			addr_toRAM   = data_fromRAM[12:0];
			num1Next     = 0;
			wrEn         = 0;
			data_toRAM   = 0;
			stateNext    = 2;
			if(operand1Next == 0)begin
				stateNext = 4;
				addr_toRAM = 4;
			end
		end
		2: begin         // read *A
			pCounterNext = pCounter;
			operand1Next = operand1;
			opcodeNext   = opcode;
			num1Next     = data_fromRAM;
			stateNext = 3;
		end
		3: begin            
			pCounterNext = pCounter + 1;
			opcodeNext = opcode;
			operand1Next = operand1;
			if(opcode == 3'b000) // ADD
				WNext = num1 + W;
			if(opcode == 3'b001) // NAND
				WNext = ~( num1 & W);
			if(opcode == 3'b010)begin // SRL
				if(num1 <= 16)
					WNext = W >> num1;
				else
					WNext = W << (num1 -16);
			end
			if(opcode == 3'b011) // LT
				WNext = W < num1;
			if(opcode == 3'b100)begin // BZ
				if( W == 0 ) 
					pCounterNext = num1;
			end
			if(opcode == 3'b101)begin // CP2W
				WNext = num1;
				data_toRAM = num1;
				end
			if(opcode == 3'b110)begin // CPfW
				wrEn = 1;
				data_toRAM = W;
				addr_toRAM   = operand1;
			end
			if(opcode == 3'b111) // MUL
				WNext = W * num1 ;
			 stateNext = 0;
		end
		
		4: begin
			pCounterNext = pCounter;
			operand1Next = operand1;
			opcodeNext   = opcode;
			addr_toRAM   = data_fromRAM;
			num1Next   = data_fromRAM;
			stateNext = 5;
		end
		5: begin
			pCounterNext = pCounter;
			operand1Next = operand1;
			opcodeNext   = opcode;
			num1Next    = data_fromRAM;//**4
			addr_toRAM  = operand1; 
			stateNext = 3;
			if(opcode == 3'b110)begin // CPfW
				wrEn = 1;
				data_toRAM = W;
				addr_toRAM   = num1;
				stateNext = 0;
				pCounterNext = pCounter+1;
			end
		end
		6: begin
			pCounterNext = pCounter;
			operand1Next = operand1;
			opcodeNext   = opcode;
			wrEn         = 0;
			data_toRAM   = num1;
			stateNext = 2;
		end
		default: begin
			stateNext    = 0;
			pCounterNext = 0;
			opcodeNext   = 0;
			operand1Next = 0;
			num1Next     = 0;
			addr_toRAM   = 0;
			wrEn         = 0;
			data_toRAM   = 0;
			starANext    = 0;
		end
	endcase

end

endmodule


