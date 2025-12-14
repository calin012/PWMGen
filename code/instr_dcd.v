module instr_dcd (
    input  clk,
    input  rst_n,

    input        byte_sync,
    input  [7:0] data_in,
    output reg [7:0] data_out,

    output reg       read,
    output reg       write,
    output reg [5:0] addr,
    input  [7:0]     data_read,
    output reg [7:0] data_write
);

    localparam S_CMD  = 1'b0;
    localparam S_DATA = 1'b1;

    reg state;
    reg rw;
    reg [5:0] latched_addr;

    // internal one-cycle strobes so regs can see them
    reg read_stb;
    reg write_stb;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_CMD;
            rw           <= 1'b0;
            latched_addr <= 6'd0;

            addr       <= 6'd0;
            data_out   <= 8'h00;
            data_write <= 8'h00;

            read_stb  <= 1'b0;
            write_stb <= 1'b0;

            read  <= 1'b0;
            write <= 1'b0;
        end else begin
            // default: deassert external strobes
            read  <= read_stb;
            write <= write_stb;

            // clear strobes after they have been presented for a full cycle
            read_stb  <= 1'b0;
            write_stb <= 1'b0;

            if (byte_sync) begin
                case (state)
                    S_CMD: begin
                        rw           <= data_in[7];
                        latched_addr <= data_in[5:0];  // Testbench expects direct addr
                        addr         <= data_in[5:0];

                        if (!data_in[7]) begin
                            // read command: regs has combinational data_read, so drive immediately
                            data_out  <= data_read;
                            read_stb  <= 1'b1;
                        end

                        state <= S_DATA;
                    end

                    S_DATA: begin
                        addr <= latched_addr;

                        if (rw) begin
                            data_write <= data_in;
                            write_stb  <= 1'b1; // will be seen by regs next clk edge
                        end

                        state <= S_CMD;
                    end
                endcase
            end
        end
    end
endmodule
