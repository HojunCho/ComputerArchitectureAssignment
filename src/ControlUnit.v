`include "opcodes.v" 																																					`include "opcodes.v" 	   
 			
module ControlUnit (clk, reset_n, num_inst, inst, ctrlSignals, bcond, is_halted);																												  
	input clk;
	input reset_n;
	output reg [`WORD_SIZE-1:0] num_inst;
	input [`WORD_SIZE-1:0] inst;
	output reg [`CtrlSigNum-1:0] ctrlSignals;
	input [`WORD_SIZE-1:0] bcond;
	output reg is_halted;
	
	wire [3:0]opCode = inst[`WORD_SIZE - 1 : `WORD_SIZE - 4];
	wire [5:0]funcCode  = inst[5:0]; 
	
	parameter IF = 4, ID = 0, EXE = 1, MEM = 2, WB = 3;
	reg [2:0] state;					
	reg [2:0] FSMmap [0:4][1:0];
	
	initial begin
		state = IF;
			
		FSMmap [0][ID] = EXE;		// ADD, SUB, AND, ORR, NOT, TCP, SHL, SHR,, ADI, ORI, LHI
		FSMmap [0][EXE] = WB;
		FSMmap [0][WB] = IF;
										  
		FSMmap [1][ID] = EXE;		// LWD
		FSMmap [1][EXE] = MEM;
		FSMmap [1][MEM] = WB;
		FSMmap [1][WB] = IF;
			
		FSMmap [2][ID] = EXE;		// SWD
		FSMmap [2][EXE] = MEM;
		FSMmap [2][MEM] = IF;
		
		FSMmap [3][ID] = EXE;		// BNE, BEQ, BGZ, BLZ
		FSMmap [3][EXE] = IF;
		
		FSMmap [4][ID] = IF;			// JMP, JAL, JPR, JRL, WWD, HLT
	end
	
	reg reBcond;
	always @* begin
		case (opCode)
			`BNE_OP	: reBcond = bcond != 0;
			`BEQ_OP	: reBcond = bcond == 0;
			`BGZ_OP	: reBcond = bcond > 0;
			`BLZ_OP	: reBcond = bcond < 0;
		endcase
	end
	
	always @* begin
		ctrlSignals[PCLatch] = state == ID ||state == EXE && reBcond;	// PC Latch
		
		case (state)								 													// IorD
			IF		: ctrlSignals[IorD] = 0;
			MEM	: ctrlSignals[IorD] = 1;
			default	: ctrlSignals[IorD] = X;
		endcase
		
		ctrlSignals[MemRead] = state == MEM && opCode == `SWD_OP;	// Memory Read
		ctrlSignals[MemWrite] = state == MEM && opCode == `LWD_OP;	// Memory Write
		ctrlSignals[IRWrite] = state == IF;													// IR Latch
			
		case (state)																					// PC Source
			ID		: ctrlSignals[PCSrc] = opCode == `JMP_OP || opCode == `JAL_OP || opCode == `ALU_OP && (funcCode == INST_FUNC_JPR || funcCode == INST_FUNC_JRL);
			EXE	: ctrlSignals[PCSrc] = 0;
			default	: ctrlSignals[PCSrc] = X;
		endcase
		
		ctrlSignals[MemtoReg] = state == WB ? opCode == `LWD_OP : X;	// Mem to Register
		
		case (state)
			IF, EXE, MEM	: ctrlSignals[RegWrite] = 0;
			ID		: ctrlSignals[RegWrite] = opCode == `ALU_OP && (funcCode == INST_FUNC_JPR || funcCode == INST_FUNC_JRL);
			WB	: ctrlSignals[RegWrite]
		endcase	
	end
																	
	always @ (posedge clk) begin
		if (!reset_n)
			state <= IF;
		else begin
			if (state == IF)
				state <= ID;
			else begin
				case (opCode)
					`ALU_OP : state <= funcCode < 8 ? FSMmap[0][state[1:0]] : FSMmap[4][state[1:0]];
					`ADI_OP, `ORI_OP, `LHI_OP : state <= FSMmap[0][state[1:0]];
					`LWD_OP	: state <= FSMmap[1][state[1:0]];
					`SWD_OP	: state <= FSMmap[2][state[1:0]];
					`BNE_OP, `BEQ_OP, `BGZ_OP, `BLZ_OP	: state <= FSMmap[3][state[1:0]];
					`JMP_OP, `JAL_OP	: state <= FSMmap[4][state[1:0]];
				endcase
			end
		end
	end
endmodule