`timescale 1ps / 1ps

module tb ();
	initial $dumpfile("tb.vcd"); // ダンプファイル指定
	initial $dumpvars(0, tb);
	initial $dumpvars(0, dbg);
	initial $dumpvars(0, disp);

	// --------------------------------------------------------------------
	//	clock
	// --------------------------------------------------------------------
	localparam		clk_base	= 1_000_000_000/108_000;	//	ps
	reg				reset_n;
	reg				clk,clk2=0;				//	85.90908MHz
	reg [31:0] tim = 0, t = 0;
	always #(clk_base/2) begin
		clk <= ~clk;
	end
	always @(posedge clk) begin
		tim <= tim+1;
		clk2 <= ~clk2;
	end
	// --------------------------------------------------------------------
	// sdram implementation
	// --------------------------------------------------------------------
	wire			O_sdram_clk;
	wire			O_sdram_cke;
	wire			O_sdram_cs_n;		// chip select
	wire			O_sdram_cas_n;		// columns address select
	wire			O_sdram_ras_n;		// row address select
	wire			O_sdram_wen_n;		// write enable
	wire	[31:0]	IO_sdram_dq;		// 32 bit bidirectional data bus
	wire	[10:0]	O_sdram_addr;		// 11 bit multiplexed address bus
	wire	[ 1:0]	O_sdram_ba;			// two banks
	wire	[ 3:0]	O_sdram_dqm;		// data mask
	mt48lc2m32b2 u_sdram (
		IO_sdram_dq,
        O_sdram_addr,
		O_sdram_ba,
		O_sdram_clk,
		O_sdram_cke,O_sdram_cs_n,
		O_sdram_ras_n,O_sdram_cas_n,O_sdram_wen_n,
        O_sdram_dqm);
	// --------------------------------------------------------------------
	// sdram controller
	// --------------------------------------------------------------------
	wire			sdram_init_busy;
	wire			sdram_busy;
	reg				mreq_n;
	reg		[22:0]	address;
	reg				wr_n;
	reg				rd_n;
	reg				rfsh_n;
	reg		[ 7:0]	wdata;
	wire	[31:0]	rdata;
	wire			rdata_en;
	ip_sdram u_sdram_controller (
		.reset_n			( reset_n			),
		.clk				( clk				),
		.clk_sdram			( clk				),
		.sdram_init_busy	( sdram_init_busy	),
		.sdram_busy			( sdram_busy		),
		.mreq_n				( mreq_n			),
		.address			( address			),
		.wr_n				( wr_n				),
		.rd_n				( rd_n				),
		.rfsh_n				( rfsh_n			),
		.wdata				( wdata				),
		.rdata				( rdata				),
		.rdata_en			( rdata_en			),
		.O_sdram_clk		( O_sdram_clk		),
		.O_sdram_cke		( O_sdram_cke		),
		.O_sdram_cs_n		( O_sdram_cs_n		),
		.O_sdram_cas_n		( O_sdram_cas_n		),
		.O_sdram_ras_n		( O_sdram_ras_n		),
		.O_sdram_wen_n		( O_sdram_wen_n		),
		.IO_sdram_dq		( IO_sdram_dq		),
		.O_sdram_addr		( O_sdram_addr		),
		.O_sdram_ba			( O_sdram_ba		),
		.O_sdram_dqm		( O_sdram_dqm		)
	);
	// --------------------------------------------------------------------
	// debug function
	// --------------------------------------------------------------------
	reg     [8*16]  disp;
	reg     [8*16]  dbg;
	reg     [8:0] cmd_cnt = 0;
	wire    [2:0]   cmd = {O_sdram_ras_n,O_sdram_cas_n,O_sdram_wen_n};
	reg [2:0] cmd1 = 7;
	wire [8*16] dcmd;
	assign dcmd = (cmd_cnt==0) ? ""
	                 : (cmd == 'b111) ? dcmd
					 : (cmd == 'b011) ? "ACTIVE"
					 : (cmd == 'b101) ? "READ"
					 : (cmd == 'b100) ? "WRITE"
					 : (cmd == 'b110) ? "BURST"
					 : (cmd == 'b010) ? "PRECHARGE"
					 : (cmd == 'b001) ? "REFRESH"
					 : (cmd == 'b000) ? "LOAD" : "";

    always @(posedge clk) begin
		cmd1 <= cmd;
		if (cmd1==7 && cmd != 7) cmd_cnt = 7;
		if (cmd_cnt>0) begin
			cmd_cnt = cmd_cnt - 1;
		end
    end

	// --------------------------------------------------------------------
	// task
	// --------------------------------------------------------------------
	task write_data(
		input	[22:0]	p_address,
		input	[7:0]	p_data
	);
		$display( "%08d: write_data( 0x%06X, 0x%02X )", tim, p_address, p_data );
		disp<="write";t<=tim;
		address		<= p_address;
		wdata		<= p_data;
		mreq_n		<= 1'b0;
		wr_n		<= 1'b0;
		@( posedge clk );
		while( sdram_busy ) begin
			disp<="wait";t<=tim;
			@( posedge clk );
		end
		disp<="activate";t<=tim;
		mreq_n		<= 1'b1;
		wr_n		<= 1'b1;
		@( posedge clk );
	endtask: write_data

	// --------------------------------------------------------------------
	task read_data(
		input	[22:0]	p_address,
		input	[31:0]	p_data
	);
		disp<="read";t<=tim;
		address		<= p_address;
		mreq_n		<= 1'b0;
		rd_n		<= 1'b0;
		@( posedge clk );
		while( sdram_busy ) begin
			@( posedge clk );
		end
		mreq_n		<= 1'b1;
		rd_n		<= 1'b1;
		@( posedge clk );
		disp<="activate";t<=tim;
		while( !rdata_en ) begin
			@( posedge clk );
		end
		$display( "%08d read_data( 0x%06X, 0x%02X )", tim, p_address, p_data );
		assert( rdata == p_data );
		if( rdata != p_data ) begin
			$display( "-- p_data = %08X", p_data );
		end
	endtask: read_data

	// --------------------------------------------------------------------
	//	Test bench
	// --------------------------------------------------------------------
	initial begin
		reset_n = 0;
		clk = 0;
		mreq_n = 1;
		wr_n = 1;
		rd_n = 1;
		rfsh_n = 1;
		address = 0;
		wdata = 0;

		@( negedge clk );
		@( negedge clk );
		@( posedge clk );

		reset_n			= 1;
		@( posedge clk );

		$display( "init -------------------------" );
		dbg="**init";
		while( sdram_init_busy ) begin
			@( posedge clk );
		end
		$display( "start -------------------------" );
		dbg="**start";
		repeat( 16 ) @( posedge clk );
		dbg="wait vsync";
		repeat( 300 ) @( posedge clk );
		dbg="**write";

		$display( "write -------------------------" );
		write_data( 'h000000, 'h12 );
		write_data( 'h000001, 'h23 );
		write_data( 'h000002, 'h34 );
		write_data( 'h000003, 'h45 );
		write_data( 'h000004, 'h56 );
		write_data( 'h000005, 'h67 );
		write_data( 'h000006, 'h78 );
		write_data( 'h000007, 'h89 );

		dbg="**read";
		$display( "read -------------------------" );
		read_data(  'h000000, 'h45342312 );
		read_data(  'h000001, 'h45342312 );
		read_data(  'h000002, 'h45342312 );
		read_data(  'h000003, 'h45342312 );

		read_data(  'h000004, 'h89786756 );


		read_data(  'h000007, 'h89786756 );

		read_data(  'h000003, 'h45342312 );

		$finish;
	end
endmodule
