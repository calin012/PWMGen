// instr_dcd.v
// Two-phase instruction decoder:
// - First byte: setup (R/W bit7, High/Low bit6, addr bits [5:0])
// - Second byte: data phase -> either write data into registers or provide data_out for SPI to shift out.

module instr_dcd (
    // peripheral clock signals
    input clk,
    input rst_n,
    // towards SPI slave interface signals
    input byte_sync,            
    input[7:0] data_in,         
    output reg[7:0] data_out,   
    // register access signals
    output reg read,            
    output reg write,           
    output reg[5:0] addr,      
    input[7:0] data_read,       
    output reg[7:0] data_write  
);

    // FSM definition 
    reg state;
    localparam S_SETUP = 1'b0;
    localparam S_DATA  = 1'b1;

    reg rw;
    reg highlow;
    reg [5:0] base_addr;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_SETUP;
            read <= 1'b0;
            write <= 1'b0;
            addr <= 6'h00;
            data_out <= 8'h00;
            data_write <= 8'h00;
            rw <= 1'b0;
            highlow <= 1'b0;
            base_addr <= 6'h00;
        end else begin
            read <= 1'b0;
            write <= 1'b0;

            if (byte_sync) begin
                if (state == S_SETUP) begin
                    // decode setup byte
                    rw <= data_in[7];
                    highlow <= data_in[6];
                    base_addr <= data_in[5:0];
                    // compute target byte address:
                    // if High/Low == 0 -> target address = base_addr (LSB)
                    // if High/Low == 1 -> target address = base_addr + 1 (MSB)
                    addr <= data_in[5:0] + (data_in[6] ? 6'd1 : 6'd0);
                    // prepare data_out for read-case
                    data_out <= 8'h00;
                    state <= S_DATA;
                end else begin
                    // DATA phase: either write to registers or prepare read data
                    if (rw) begin
                        data_write <= data_in;
                        write <= 1'b1;
                    end else begin
                        data_out <= data_read;
                        read <= 1'b1;
                    end
                    // After data-phase go back to setup
                    state <= S_SETUP;
                end
            end
        end
    end

endmodule
