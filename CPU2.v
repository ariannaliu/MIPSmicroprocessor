`timescale 1ns / 1ps

module CPU(input wire clock, input wire start, input [31:0] i_datain);

	reg[31:0] IM[31:0];    //32 lines instruction memory place;
	reg[31:0] DM[31:0];    //32 lines for data memory;
	reg[31:0] pc;
	reg[31:0] pcf;
	reg[31:0] pcf_4, pcd_4, pce_4, pcd_branch, pcm_branch;
	reg[31:0] gr[31:0];		//32 general registers 
	reg[31:0] instr;
	reg[31:0] d_datain;
	reg[5:0] opcode, func;
	reg[1:0] alu_op;
	reg[3:0] aluctrD, aluctrE;
	reg regDstD, regDstE;
	reg aluSrcD, aluSrcE;
	reg memToRegD, memToRegE, memToRegM, memToRegW;
	reg regWriteD, regWriteE, regWriteM, regWriteW;
	reg memReadD, memReadE, memReadM;
	reg memWriteD, memWriteE, memWriteM;
//	reg branchD, branchE, branchM;
	reg branchD, beqbneChoose;
	reg shamtFlagD, shamtFlagE;
	reg[4:0] rs, rt, rtD, rdD, shamtD,shamtE, rtE,rdE, writeRegE, writeRegM, writeRegW;
	reg j, jr, jal;
	reg[15:0] imm;
	reg[31:0] reg_A, reg_B, reg_AE, reg_BE;
	reg uf;    //unsigned extension flag;
	reg[31:0] signImmD, signImmE;
	reg[31:0] aluOutE, aluOutM,aluOutW;
	reg signed [31:0] r_A, r_B;
	reg zf, zfM, ovf, nf;
	reg[31:0] writeDataE, writeDataM;
	reg pcSrcM, pcSrcD;
	reg equalD;
	reg[31:0] readDataM, readDataW;
	reg[31:0] resultW;
	reg[25:0] target;
	reg[31:0] jump;

always @(start)
	begin
		gr[0] = 32'h00000000;
		pc = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
		DM[1] = 32'h0000_00ab;
		DM[2] = 32'h0000_3c00;
		DM[3] = 32'h0000_0001;
		DM[4] = 32'h8000_0000;
		DM[5] = 32'h0000_0001;
	end



always @(posedge clock)       //second clock
	begin
	pcf <= pc;
	pc <= pc + 32'h00000004;
	end
	
always @(*)
	begin
	instr = i_datain;
	pcf_4 = pcf + 32'h00000004;
	
//	pc = pcf_4;
	end
	
always @(posedge clock)		  //thrid clock
	begin
	d_datain <= instr;
	pcd_4 <= pcf_4;
	end

always @(*)	
	begin
	opcode = d_datain[31:26];
	func = d_datain[5:0];
	alu_op[0] = (~opcode[5])&(~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(~opcode[0]);
	alu_op[1] = (~opcode[5])&(~opcode[4])&(~opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]);
	aluctrD[3] = 0;
	aluctrD[2] = (alu_op[0])|((alu_op[1])&(func[1]));
	aluctrD[1] = (~alu_op[1])|(~func[2]);
	aluctrD[0] = ((func[0])|(func[3]))&(alu_op[1]);
	regDstD = (~opcode[5])&(~opcode[4])&(~opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]);
	aluSrcD = ((opcode[5])&(~opcode[4])&(~opcode[3])&(~opcode[2])&(opcode[1])&(opcode[0]))|
			((opcode[5])&(~opcode[4])&(opcode[3])&(~opcode[2])&(opcode[1])&(opcode[0]))|
			((~opcode[5])&(~opcode[4])&(opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]))|      //addi
			((~opcode[5])&(~opcode[4])&(opcode[3])&(~opcode[2])&(~opcode[1])&(opcode[0]))|		 //addiu
			((~opcode[5])&(~opcode[4])&(opcode[3])&(opcode[2])&(~opcode[1])&(~opcode[0]))|		 //andi
			((~opcode[5])&(~opcode[4])&(opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0]))|		 //ori
			((~opcode[5])&(~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(~opcode[0]))|		 //beq
			((~opcode[5])&(~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0]));		 //bne
			
	uf = ((~opcode[5])&(~opcode[4])&(opcode[3])&(opcode[2])&(~opcode[1])&(~opcode[0]))|		 //andi
		((~opcode[5])&(~opcode[4])&(opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0]));		 //ori
			
	memToRegD = ((opcode[5])&(~opcode[4])&(~opcode[3])&(~opcode[2])&(opcode[1])&(opcode[0]));
	regWriteD = ((~opcode[5])&(~opcode[4])&(~opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]))|   //all R-type
				((opcode[5])&(~opcode[4])&(~opcode[3])&(~opcode[2])&(opcode[1])&(opcode[0]))|	//lw
				((~opcode[5])&(~opcode[4])&(opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]))|	//addi
				((~opcode[5])&(~opcode[4])&(opcode[3])&(~opcode[2])&(~opcode[1])&(opcode[0]))|   //addiu
				((~opcode[5])&(~opcode[4])&(opcode[3])&(opcode[2])&(~opcode[1])&(~opcode[0]))| 		//andi
				((~opcode[5])&(~opcode[4])&(opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0]));  //ori
	memReadD = ((opcode[5])&(~opcode[4])&(~opcode[3])&(~opcode[2])&(opcode[1])&(opcode[0]));
	memWriteD = ((opcode[5])&(~opcode[4])&(opcode[3])&(~opcode[2])&(opcode[1])&(opcode[0]));
	branchD = ((~opcode[5])&(~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(~opcode[0]))|  //beq
				((~opcode[5])&(~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0]));  //bne
	shamtFlagD = ((~func[5])&(~func[4])&(~func[3])&(~func[2])&(~func[1])&(~func[0]))|		//sll 000 000
					((~func[5])&(~func[4])&(~func[3])&(~func[2])&(func[1])&(~func[0]))|		//srl 000 010
					((~func[5])&(~func[4])&(~func[3])&(~func[2])&(func[1])&(func[0]));		//sra 000 011
					
	beqbneChoose = ((~opcode[5])&(~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0])); //bne
	j = ((~opcode[5])&(~opcode[4])&(~opcode[3])&(~opcode[2])&(opcode[1])&(~opcode[0])); //j
	jal = ((~opcode[5])&(~opcode[4])&(~opcode[3])&(~opcode[2])&(opcode[1])&(opcode[0])); //jal
	jr = ((~opcode[5])&(~opcode[4])&(~opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0])&(~func[5])&(~func[4])&(func[3])&(~func[2])&(~func[1])&(~func[0])); //jr
	
	if(((func == 6'b000000)&(opcode == 6'b000000))|((func == 6'b000100)&(opcode == 6'b000000)))		//sll sllv
		begin
		aluctrD = 4'b1000;
		end
		
	if(((func == 6'b000010)&(opcode == 6'b000000))|((func == 6'b000110)&(opcode == 6'b000000)))		//srl srlv
		begin
		aluctrD = 4'b1001;
		end
		
	if(((func == 6'b000011)&(opcode == 6'b000000))|((func == 6'b000111)&(opcode == 6'b000000)))		//sra srav
		begin
		aluctrD = 4'b1010;
		end
	
	if((func == 6'b101010)&(opcode == 6'b000000))  //slt
		begin
		aluctrD = 4'b1100;
		end
	
	if((func == 6'b001000)&(opcode == 6'b000000))  //jr
		begin
		aluctrD = 4'b1101;
		end
	
	case(opcode)  //j
	6'b000010:
		begin
		aluctrD = 4'b1110;
		end
	endcase
	
	case(opcode)  //jal
	6'b000011:
		begin
		aluctrD = 4'b1111;
		end
	endcase
		
	case(opcode)  //addiu
	6'b001001:
		begin
		aluctrD = 4'b0011;
		end
	endcase
	
	case(opcode)  //andi
	6'b001100:
		begin
		aluctrD = 4'b0000;
		end
	endcase
	
	case(opcode)  //ori
	6'b001101:
		begin
		aluctrD = 4'b0001;
		end
	endcase
	
	case(opcode)  //bne
	6'b000101:
		begin
		aluctrD = 4'b1011;
		end
	endcase
	
	rs = d_datain[25:21];
	rt = d_datain[20:16];
	rtD = d_datain[20:16];
	rdD = d_datain[15:11];
	imm = d_datain[15:0];
	shamtD = d_datain[10:6];
	target = d_datain[25:0];
	
	reg_A = gr[rs];
	reg_B = gr[rt];
	
	if(uf == 1'b1)
		begin
		signImmD = {{16{1'b0}}, imm};
		end
	else
		begin
		signImmD = {{16{imm[15]}}, imm};
		end
		
	pcd_branch = pcd_4 + (signImmD << 2);	
	equalD = (reg_A == reg_B) ? 1'b1:1'b0;
	pcSrcD = branchD & ((equalD)&(~beqbneChoose)|(~equalD)&(beqbneChoose));
	
	//j jr jal
	if(j == 1'b1)
		begin
		jump = {pc[31:26], target};
		pc = (jump << 2) + 32'h00000004;
		end
	else if(jal == 1'b1)
		begin
		gr[31] = pc + 32'h00000004;
		jump = {pc[31:26], target};
		pc = (jump << 2) + 32'h00000004;
		end
	else if(jr == 1'b1)
		begin
		jump = gr[rs];
		pc = (jump <<2 ) + 32'h00000004;
		end
	
	//branch 
	if (pcSrcD == 1'b1)
		begin
		pc = pcd_branch;
		end
	
	end
	
always @(posedge clock)			//the forth clock
	begin
	aluctrE <= aluctrD;
	regDstE <= regDstD;
	aluSrcE <= aluSrcD;
	memToRegE <= memToRegD;
	regWriteE <= regWriteD;
	memReadE <= memReadD;
	memWriteE <= memWriteD;
//	branchE <= branchD;
	reg_AE <= reg_A;
	reg_BE <= reg_B;
	signImmE <= signImmD;
	shamtE <= shamtD;
	shamtFlagE <= shamtFlagD;
	rtE <= rtD;
	rdE <= rdD;
//	pce_4 <= pcd_4;
	end

always @(*)
	begin
	writeDataE = reg_BE;
	//ALU part
	if(aluSrcE == 1'b1)
		begin
		reg_BE = signImmE;
		end
	
	case(aluctrE)    //lw, sw, add addi    signed add
	4'b0010:
		begin
		r_A = reg_AE;
		r_B = reg_BE;
		aluOutE = r_A + r_B;
		zf = (aluOutE == 32'b0000_0000_0000_0000_0000_0000_0000_0000) ? 1'b1:1'b0;
		nf = (aluOutE[31] == 1) ? 1'b1: 1'b0;
		end
	endcase
	
	case(aluctrE)    //addu addiu    unsigned add
	4'b0011:
		begin
		aluOutE = reg_AE + reg_BE;
		zf = (aluOutE == 32'b0000_0000_0000_0000_0000_0000_0000_0000) ? 1'b1:1'b0;
		nf = 0;
		end
	endcase
	
	case(aluctrE)    //sub beq    signed
	4'b0110:
		begin
		r_A = reg_AE;
		r_B = reg_BE;
		aluOutE = r_A - r_B;
		zf = (aluOutE == 32'b0000_0000_0000_0000_0000_0000_0000_0000) ? 1'b1:1'b0;
		nf = (aluOutE[31] == 1) ? 1'b1: 1'b0;
		end
	endcase
	
	case(aluctrE)    //subu  unsigned
	4'b0111:
		begin
		aluOutE = reg_AE - reg_BE;
		zf = (aluOutE == 32'b0000_0000_0000_0000_0000_0000_0000_0000) ? 1'b1:1'b0;
		nf = (aluOutE[31] == 1) ? 1'b1: 1'b0;
		end
	endcase
	
	
	
	case(aluctrE)		//and andi
	4'b0000:
		begin
		aluOutE = reg_AE & reg_BE;
		zf = 1'b0;
		nf = 1'b0;
		end
	endcase
	
	case(aluctrE)		//or ori
	4'b0001:
		begin
		aluOutE = reg_AE | reg_BE;
		zf = 1'b0;
		nf = 1'b0;
		end
	endcase
	
	case(aluctrE)		//nor
	4'b0101:
		begin
		aluOutE = ~(reg_AE | reg_BE);
		zf = 1'b0;
		nf = 1'b0;
		end
	endcase
	
	case(aluctrE)		//xor
	4'b0100:
		begin
		aluOutE = ((~reg_AE)&reg_BE)|((reg_AE)&(~reg_BE));
		zf = 1'b0;
		nf = 1'b0;
		end
	endcase
	
	case(aluctrE)		//sll sllv
	4'b1000:
		begin
		if(shamtFlagE == 1'b1)  //sll
			begin
				reg_AE = {{27{1'b0}}, shamtE};
			end
		aluOutE = reg_BE << reg_AE;
		zf = (aluOutE == 32'b0000_0000_0000_0000_0000_0000_0000_0000) ? 1'b1:1'b0;
		nf = (aluOutE[31] == 1) ? 1'b1: 1'b0;
		end
	endcase
	
	case(aluctrE)		//srl srlv
	4'b1001:
		begin
		if(shamtFlagE == 1'b1)  //srl
			begin
				reg_AE = {{27{1'b0}}, shamtE};
			end
		aluOutE = reg_BE >> reg_AE;
		zf = (aluOutE == 32'b0000_0000_0000_0000_0000_0000_0000_0000) ? 1'b1:1'b0;
		nf = (aluOutE[31] == 1) ? 1'b1: 1'b0;
		end
	endcase
	
	case(aluctrE)		//sra srav
	4'b1010:
		begin
		r_B = reg_BE;
		r_A = reg_AE;
		if(shamtFlagE == 1'b1)  //sra
			begin
				r_A = {{27{1'b0}}, shamtE};
			end
		aluOutE = r_B >>> r_A;
		zf = (aluOutE == 32'b0000_0000_0000_0000_0000_0000_0000_0000) ? 1'b1:1'b0;
		nf = (aluOutE[31] == 1) ? 1'b1: 1'b0;
		end
	endcase
	
/*	case(aluctrE)		//bne
	4'b1011:
		begin
		aluOutE = signImmE;
		zf = (reg_AE == reg_BE) ? 1'b0:1'b1;
		nf = 1'b0;
		end
	endcase
*/	
	case(aluctrE)		//slt
	4'b1100:
		begin
		r_A = reg_AE;
		r_B = reg_BE;
		if (r_A < r_B)
			begin
			aluOutE = 32'b0000_0000_0000_0000_0000_0000_0000_0001;
			end
		else
			begin
			aluOutE = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
			end
		zf = 1'b0;
		nf = 1'b0;
		end
	endcase
	
	//j jr jal havent finished yet
	
	if(regDstE == 1'b0)
		begin
		writeRegE = rtE;
		end
	else
		begin
		writeRegE = rdE;
		end
	

	
	
	end
	
always @(posedge clock)			//the fifth clock
	begin
	regWriteM <= regWriteE;
	memToRegM <= memToRegE;
	memWriteM <= memWriteE;
	memReadM <= memReadE;
//	branchM <= branchE;
	zfM <= zf;
	aluOutM <= aluOutE;
	writeDataM <= writeDataE;
	writeRegM <= writeRegE;
//	pcm_branch <= pce_branch;
	end
	
always @(*)
	begin
//	pcSrcM = zfM & branchM;
	
	if(memReadM == 1'b1)     //load word lw
		begin
		readDataM = DM[aluOutM];
		end
	if(memWriteM == 1'b1)		//store word sw
		begin
		DM[aluOutM] = writeDataM;
		end	
	
	end
	
always @(posedge clock)
	begin
	regWriteW <= regWriteM;
	memToRegW <= memToRegM;
	aluOutW <= aluOutM;
	readDataW <= readDataM;
	writeRegW <= writeRegM;
	end
	
always @(*)
	begin
	if(memToRegW == 1'b1)
		begin
		resultW = readDataW;
		end
	else
		begin
		resultW = aluOutW;
		end
	
	
	if(regWriteW == 1'b1) // write back
		begin
		gr[writeRegW] = resultW;
		end
		
		
	end
	

endmodule

//This is an example for a single cycle cpu.
//You should:
//1. Extend the combinational logic part to construct a single cycle processor.(85%)
//2. Add more sequential logic to construct a pipeline processor.(100%)

/*
module CPU(
    input wire clock,
    input wire start,
    input [31:0] i_datain,
    input wire [31:0] d_datain,
    output wire [31:0] d_dataout
    );

    reg [31:0]gr[7:0];//[31:0]for 32bit MIPS processor
    reg [15:0]pc = 32'h00000000;

    reg [31:0]instr;
    reg [31:0]reg_A;
    reg [31:0]reg_B;
    reg [31:0]reg_C;
    reg [31:0]reg_C1;

    reg [5:0]opcode;
    reg [5:0]functcode;

always @(start)
    begin
        gr[0] = 32'h0000_0000;
    end

//sequential logic
always @(posedge clock)
	begin
        //pc
        pc <= pc + 32'h00000004;
        //Use if sentences to implement the multiplexier
    end

//combinational logic
always @(pc)
    begin
        instr = i_datain;
        //About Project 3
        //control unit
        opcode = instr[31:26];
        functcode = instr[5:0];
        //Please set the ALUControl with your own code.

        //reg_A and reg_B
        //lw
        if (opcode == 6'b100011)
        begin
            reg_A = gr[instr[25:21]];
            reg_B = instr[15:0];//sign extension of imm number
        end

        //R-type instruction (add etc.)
        else if (opcode == 6'b000000)
        begin
            reg_A = gr[instr[25:21]];
            reg_B = gr[instr[20:16]];
        end
        //You should do extension of this part of code with the ALU you have finished in project 3.

        //reg_C
        //lw, add, etc.
        if (opcode == 6'b100011 || opcode == 6'b000000)//Use ALUControl here after changing the control unit's code.
        reg_C = reg_A + reg_B;

        //reg_C1(Result)
        //lw, add, etc.
        if (opcode == 6'b100011)
        begin
            reg_C1 = d_datain[31:0];
        end
        //add, etc.
        else if (opcode == 6'b000000)
            reg_C1 = reg_C;
        
        //write back to general registers
        if (opcode == 6'b100011)
            gr[instr[20:16]] = reg_C1;
        else if (opcode == 6'b000000)
            gr[instr[15:11]] = reg_C1;
        //Use the RegWrite(Output of Ctrl Unit) to select.

    end


endmodule
*/                
