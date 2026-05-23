library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_reaction_timer is
    Port (
        clk       : in  STD_LOGIC;
        reset_n   : in  STD_LOGIC; -- Red CPU Reset button (Active Low)
        start_btn : in  STD_LOGIC;
        react_btn : in  STD_LOGIC;
        leds      : out STD_LOGIC_VECTOR(15 downto 0);
        seg       : out STD_LOGIC_VECTOR(6 downto 0);
        an        : out STD_LOGIC_VECTOR(7 downto 0)
    );
end top_reaction_timer;

architecture Behavioral of top_reaction_timer is
    type state_type is (IDLE, WAITING, READY, RESULT, EARLY);
    signal state : state_type := IDLE;

    signal start_db, react_db, react_prev : std_logic;
    signal lfsr        : unsigned(15 downto 0) := x"ACE1";
    signal wait_counter : unsigned(27 downto 0) := (others => '0');
    signal target_wait  : unsigned(27 downto 0);

    signal ms_tick_cnt : integer range 0 to 100000 := 0;
    signal ms_counter  : unsigned(15 downto 0) := (others => '0');
    signal final_time  : unsigned(15 downto 0) := (others => '0');

    signal show_res_sig, early_sig, fast_sig : std_logic;

begin
    -- Component Instantiations
    deb1: entity work.debounce port map(clk=>clk, btn_in=>start_btn, btn_out=>start_db);
    deb2: entity work.debounce port map(clk=>clk, btn_in=>react_btn, btn_out=>react_db);

    -- Random Delay: 1.5s Base + LFSR variation
    target_wait <= to_unsigned(150_000_000, 28) + resize(lfsr & "000_000_000", 28); --- concatenation with “000_000_000” multiples the value by 512

    -- Control Signals for Display
    show_res_sig <= '1' when state = RESULT else '0';
    early_sig    <= '1' when state = EARLY else '0';
    fast_sig     <= '1' when final_time < 300 else '0';

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state <= IDLE;
            lfsr <= x"ACE1";
            leds <= (others => '0');
        elsif rising_edge(clk) then
            react_prev <= react_db;

            -- Simple LFSR for randomness
            lfsr <= lfsr(14 downto 0) & (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));

            case state is
                when IDLE =>
                    leds <= (others => '0');
                    if start_db = '1' then
                        state <= WAITING;
                        wait_counter <= (others => '0');
                    end if;

                when WAITING =>
                    wait_counter <= wait_counter + 1;
                    if react_db = '1' and react_prev = '0' then
                        state <= EARLY;
                    elsif wait_counter >= target_wait then
                        state <= READY;
                        ms_counter <= (others => '0');
                        ms_tick_cnt <= 0;
                    end if;

                when READY =>
                    leds <= (others => '1'); -- Turn on LEDs to signal user
                    if ms_tick_cnt = 100000 then
                        ms_tick_cnt <= 0;
                        ms_counter <= ms_counter + 1;
                    else
                        ms_tick_cnt <= ms_tick_cnt + 1;
                    end if;

                    if react_db = '1' and react_prev = '0' then
                        final_time <= ms_counter;
                        state <= RESULT;
                    end if;

                when RESULT | EARLY =>
                    leds <= (others => '0');
                    if start_db = '1' then
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

    display_inst: entity work.seven_seg_driver
        port map (
            clk          => clk,
            reaction_ms  => final_time,
            is_fast      => fast_sig,
            show_results => show_res_sig,
            too_early    => early_sig,
            seg          => seg,
            an           => an
        );
end Behavioral;