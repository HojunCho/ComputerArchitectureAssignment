`include "opcodes.v" 	   
module cpu (clk, reset_n, readM, writeM, address, data, num_inst, output_port, is_halted);	
	input clk;											// clock signal   		
	input reset_n;									// active-low RESET signal			
	output readM;									// read from memory
	output writeM;									// wrtie to memory
	output [`WORD_SIZE-1:0] address;	// current address for data	
	inout [`WORD_SIZE-1:0] data;			// data being input or output								 						
	output [`WORD_SIZE-1:0] num_inst;		// number of instruction during execution  
	output [`WORD_SIZE-1:0] output_port;	// this will be used for a "WWD" instruction		 	 	 
	output is_halted;								// set if the cpu is halted
	
	wire [`WORD_SIZE-1:0] inst;		   
	wire [`CtrlSigNum-1:0] ctrlSignals;	
	wire [`WORD_SIZE-1:0] bcond;		   
									   						   	
	// Datapath 
    Datapath dpath (clk, reset_n, readM, writeM, address, data, inst, ctrlSignals, bcond, output_port);			
	
	// Controll Unit																												
	ControlUnit ctrl_unit (clk, reset_n, num_inst, inst, ctrlSignals, bcond, is_halted);	
	

endmodule							  																		  