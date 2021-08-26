`timescale 1ns/1ps
//this is for store word (sw) instruction
// general register
`define gr0  	5'b00000
`define gr1  	5'b00001
`define gr2  	5'b00010
`define gr3 	5'b00011
`define gr4  	5'b00100
`define gr5  	5'b00101
`define gr6  	5'b00110
`define gr7  	5'b00111
`define gr8  	5'b01000
`define gr9  	5'b01001
`define gr10  	5'b01010
`define gr11 	5'b01011
`define gr12  	5'b01100
`define gr13  	5'b01101
`define gr14  	5'b01110
`define gr15  	5'b01111
`define gr16  	5'b10000
`define gr17  	5'b10001
`define gr18  	5'b10010
`define gr19 	5'b10011
`define gr20  	5'b10100
`define gr21  	5'b10101
`define gr22  	5'b10110
`define gr23  	5'b10111
`define gr24  	5'b11000
`define gr25  	5'b11001
`define gr26 	5'b11010
`define gr27 	5'b11011
`define gr28  	5'b11100
`define gr29  	5'b11101
`define gr30  	5'b11110
`define gr31  	5'b11111


module CPU_test;

    // Inputs
	reg clock;
//	reg [31:0] d_datain;
	reg [31:0] i_datain;
    reg start;

//    wire [31:0] d_dataout;

    CPU uut(
        .clock(clock),
        .start(start),
		.i_datain(i_datain)
    );

    initial begin
        // Initialize Inputs
        clock = 0;
        start = 1;
//        d_datain = 0;
        i_datain = 0;

    $display("pc  : instruction: reg_A  : reg_B  : cout :  gr0   :  gr1   :  gr2   :  gr3: ");
    $monitor("%h:%b:%h:%h:%h:%h:%h:%h:%h:%h:%h:%h:%h:%h", 
       uut.pcf,  uut.d_datain, uut.aluOutE, uut.pcSrcD, uut.gr[0], uut.gr[1], uut.gr[2], uut.gr[3], uut.gr[4], uut.gr[5], uut.gr[31], uut.j, uut.jal, uut.jr);
	
	
    /*Test:*/

	#period
    i_datain <= {6'b100011, `gr0, `gr1, 16'h0005};		 //lw, load DM[5]: 32'h0000_0001 to gr[1]   => gr[1] = 1;

    #period 
    i_datain <= {6'b100011, `gr0, `gr2, 16'h0002};		 //lw, load DM[2]: 32'32'h0000_3c00 to gr[2]
	
	#period
    i_datain <= {6'b100011, `gr0, `gr4, 16'h0003};		 //lw, load DM[3]: 32'h0000_0001 to gr[4]  => gr[4] = 1;
	
	#period 
    i_datain <= {6'b100011, `gr0, `gr5, 16'h0004};		 //lw, load DM[4]: 32'h8000_0000 to gr[5]
	
	#period 
    i_datain <= {6'b000010, 26'b1000_0000_0000_0000_0000_0000_00};		 //j
	
	#period 
    i_datain <= {6'b000011, 26'b0000_0000_0000_0000_0000_0000_01};		 //jal
	
	#period 
    i_datain <= {6'b000000, `gr1, `gr0, `gr0,  5'b00000, 6'b001000};		 //jr
	
	#period 
	i_datain <= {6'b000000, `gr1, `gr2, `gr3,  5'b00000, 6'b100010}; //sub gr[1] + gr[2] = gr[3];
	
	#period 
	i_datain <= {6'b000000, `gr1, `gr2, `gr3,  5'b00000, 6'b100000}; //add gr[1] + gr[2] = gr[3];
	
	#period 
	i_datain <= {6'b000000, `gr1, `gr2, `gr3,  5'b00000, 6'b100010}; //sub gr[1] + gr[2] = gr[3];
	
	#period 
	i_datain <= {6'b000000, `gr1, `gr2, `gr3,  5'b00000, 6'b100000}; //add gr[1] + gr[2] = gr[3];

    #period $finish;
    end

parameter period = 10;
always #5 clock = ~clock;
endmodule