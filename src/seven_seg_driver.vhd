library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_seg_driver is
    Port (
        clk           : in  STD_LOGIC;
        reaction_ms   : in  unsigned(15 downto 0);
        is_fast       : in  STD_LOGIC;
        show_results  : in  STD_LOGIC;
        too_early     : in  STD_LOGIC;
        seg           : out STD_LOGIC_VECTOR(6 downto 0);
        an            : out STD_LOGIC_VECTOR(7 downto 0)
    );
end seven_seg_driver;

architecture Behavioral of seven_seg_driver is
    signal refresh_cnt  : unsigned(19 downto 0) := (others => '0');
    signal active_digit : integer range 0 to 7;
    signal char_code    : std_logic_vector(3 downto 0);
    signal is_text      : std_logic := '0';
    signal raw_seg      : std_logic_vector(6 downto 0);
begin
    -- Counter for multiplexing the 8 displays
    process(clk) begin
        if rising_edge(clk) then
            refresh_cnt <= refresh_cnt + 1;
        end if;
    end process;

    active_digit <= to_integer(refresh_cnt(19 downto 17));

    process(active_digit, reaction_ms, is_fast, show_results, too_early)
        variable val : integer;
    begin
        an <= (others => '1'); -- Default: all anodes off
        an(active_digit) <= '0'; -- Turn on current digit (Active Low)
        is_text <= '0';
        char_code <= x"0";
        raw_seg <= "1111111"; -- Default: Blank segments

if too_early = '1' then
    -- Display "Err" correctly from left to right
    case active_digit is
        when 2 => raw_seg <= "0000110"; -- E (Left-most of the three)
        when 1 => raw_seg <= "0101111"; -- r (Middle)
        when 0 => raw_seg <= "0101111"; -- r (Right-most)
        when others => raw_seg <= "1111111";
    end case;        
elsif show_results = '1' then
            val := to_integer(reaction_ms);
            case active_digit is
                -- Time Digits (BCD Extraction)
                when 0 => char_code <= std_logic_vector(to_unsigned(val mod 10, 4));
                when 1 => char_code <= std_logic_vector(to_unsigned((val/10) mod 10, 4));
                when 2 => char_code <= std_logic_vector(to_unsigned((val/100) mod 10, 4));
                
                -- Text Digits (FAST or SLOW)
                when 7 =>
                    if is_fast = '1' then raw_seg <= "0001110"; else raw_seg <= "0010010"; end if; -- F or S
                when 6 =>
                    if is_fast = '1' then raw_seg <= "0001000"; else raw_seg <= "1000111"; end if; -- A or L
                when 5 =>
                    if is_fast = '1' then raw_seg <= "0010010"; else raw_seg <= "1000000"; end if; -- S or O
                when 4 =>
                    if is_fast = '1' then raw_seg <= "0000111"; else raw_seg <= "1000001"; end if; -- t or U
                when others =>
                    raw_seg <= "1111111";
            end case;
        end if;
    end process;

    -- Hex Decoder for numeric parts (0-9)
    process(char_code, raw_seg) begin
        if raw_seg /= "1111111" then
            seg <= raw_seg;
        else
            case char_code is
                when x"0" => seg <= "1000000";
                when x"1" => seg <= "1111001";
                when x"2" => seg <= "0100100";
                when x"3" => seg <= "0110000";
                when x"4" => seg <= "0011001";
                when x"5" => seg <= "0010010";
                when x"6" => seg <= "0000010";
                when x"7" => seg <= "1111000";
                when x"8" => seg <= "0000000";
                when x"9" => seg <= "0010000";
                when others => seg <= "1111111";
            end case;
        end if;
    end process;
end Behavioral;