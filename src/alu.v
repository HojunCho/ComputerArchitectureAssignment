`timescale 1ns /100ps
`include "opcodes.v"																					 

module ALU (						   		 
	input [`WORD_SIZE-1:0] A,
	input [`WORD_SIZE-1:0] B,
	input [2:0] FuncCode,						  
	output reg [`WORD_SIZE-1:0] C,	   
	output reg OverflowFlag
	);									
										    						
	reg MSB;
	
	always @* begin			   
		case(FuncCode)		 
			`FUNC_ADD : {MSB, C} = {A[`WORD_SIZE - 1], A} + {B[`WORD_SIZE - 1], B};
			`FUNC_SUB : {MSB, C} = {A[`WORD_SIZE - 1], A} - {B[`WORD_SIZE - 1], B};				 
			`FUNC_AND : C = A & B;
			`FUNC_ORR : C = A | B; 					    
			`FUNC_NOT : C = ~A; 
			`FUNC_TCP : C = ~A + 1;
			`FUNC_SHL : C = A <<< 1;
			`FUNC_SHR : C = A >>> 1;		  				
		endcase
		if (FuncCode == `FUNC_ADD || FuncCode == `FUNC_SUB)
			OverflowFlag = MSB ^ C[`WORD_SIZE - 1];
		else
			OverflowFlag = 0;
	end			  	
endmodule			
	