// UART Transmitter with configurable baud rate
module uart_tx #(
    parameter integer CLK_FREQ = 50_000_000,  // Clock frequency in Hz
    parameter integer BAUD_RATE = 9600       // Baud rate for UART
)(
    input logic i_clk,           // Clock signal
    input logic i_rst_n,         // Reset signal (active low)
    input logic i_tx_start,      // Start signal to transmit data
    input logic [7:0] i_data,    // 8-bit data to be transmitted

    output logic o_tx,           // UART transmit line
    output logic o_tx_busy       // Busy signal to indicate transmission in progress
);

    // Calculate clock cycles per bit
    localparam integer CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;

    // State encoding
    typedef enum logic [1:0] {
        IDLE    = 2'b00, // Idle state
        START   = 2'b01, // Start bit transmission
        DATA    = 2'b10, // Data bits transmission
        STOP    = 2'b11  // Stop bit transmission
    } uart_state_t;

    uart_state_t state;             // Current state
    logic [$clog2(CYCLES_PER_BIT) - 1:0] bit_timer; // Timer for bit duration
    logic [3:0] bit_index;          // Index for data bits

    // Internal signals
    logic [7:0] tx_shift_reg;       // Shift register for data transmission

    // Sequential logic for state machine
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= IDLE;          // Reset to IDLE state
            bit_timer <= 0;
            bit_index <= 0;
            tx_shift_reg <= 8'b0;
            o_tx <= 1'b1;           // Idle line is high
            o_tx_busy <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    o_tx <= 1'b1;   // Keep line idle
                    o_tx_busy <= 1'b0;

                    if (i_tx_start) begin
                        state <= START;           // Transition to START state
                        tx_shift_reg <= i_data;   // Load data into shift register
                        bit_timer <= 0;
                        bit_index <= 0;
                        o_tx_busy <= 1'b1;
                    end
                end

                START: begin
                    o_tx <= 1'b0;   // Transmit start bit

                    if (bit_timer == CYCLES_PER_BIT - 1) begin
                        state <= DATA;            // Transition to DATA state
                        bit_timer <= 0;
                    end else begin
                        bit_timer <= bit_timer + 1;
                    end
                end

                DATA: begin
                    o_tx <= tx_shift_reg[0];      // Transmit LSB of shift register

                    if (bit_timer == CYCLES_PER_BIT - 1) begin
                        bit_timer <= 0;
                        tx_shift_reg <= tx_shift_reg >> 1; // Shift data
                        bit_index <= bit_index + 1;

                        if (bit_index == 7) begin
                            state <= STOP;        // Transition to STOP state
                        end
                    end else begin
                        bit_timer <= bit_timer + 1;
                    end
                end

                STOP: begin
                    o_tx <= 1'b1;   // Transmit stop bit

                    if (bit_timer == CYCLES_PER_BIT - 1) begin
                        state <= IDLE;           // Return to IDLE state
                        o_tx_busy <= 1'b0;
                    end else begin
                        bit_timer <= bit_timer + 1;
                    end
                end

                default: begin
                    state <= IDLE; // Default to IDLE
                end
            endcase
        end
    end
endmodule
