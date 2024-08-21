/* 
 * File: dromajo_bootrom.sv
 *
 * Description: bootrom that gets synced with dromajo for
 * cosimulation purposes.
 *
 */

module dromajo_bootrom (
   input  logic         clk_i,
   input  logic         req_i,
   input  logic [63:0]  addr_i,
   output logic [63:0]  rdata_o
);
    localparam int RomSize = 4096;
    logic [63:0] mem[RomSize-1:0];

    initial begin
      integer hex_file, num_bytes;
      longint address, value;
      string f_name;
      bit [7:0] bdata;
      bit [7:0] data[7:0];
      // init to 0
      for (int k=0; k<RomSize; k++) begin
        mem[k] = 0;
      end

      // sync with dromajo
      if ($value$plusargs("checkpoint=%s", f_name)) begin
        hex_file = $fopen({f_name,".bootram"}, "rb");
        address = 0;
        
        while (!$feof(hex_file)) begin
          for( int i = 0; i < 8; i++ ) begin
            num_bytes = $fread( bdata, hex_file );
            data[i] = bdata;
          end
          value = {data[7],data[6],data[5],data[4],data[3],data[2],data[1],data[0]};
          if( address <= 5 ) begin
            $display("%d || %h", address, value);
          end
          mem[address] = value;
          address = address + 1;
        end
        $display("Done syncing RAM with dromajo...\n");
      end else begin
        $display("Dromajo error: provide path to a checkpoint.\n");
      end
    end

    logic [$clog2(RomSize)-1:0] addr_q;

    always_ff @(posedge clk_i) begin
        if (req_i) begin
            addr_q <= addr_i[$clog2(RomSize)-1+3:3];
        end
    end

    // this prevents spurious Xes from propagating into
    // the speculative fetch stage of the core
    assign rdata_o = (addr_q < RomSize) ? mem[addr_q] : '0;
endmodule
