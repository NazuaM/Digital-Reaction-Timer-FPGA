library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce is
    Port (
        clk     : in  STD_LOGIC;
        btn_in  : in  STD_LOGIC;
        btn_out : out STD_LOGIC
    );
end debounce;

architecture Behavioral of debounce is
    signal counter : unsigned(19 downto 0) := (others => '0');
    signal sync    : std_logic_vector(1 downto 0) := "00";
    signal stable  : std_logic := '0';
begin
    process(clk) begin
        if rising_edge(clk) then
            sync <= sync(0) & btn_in;
            if sync(1) = stable then
                counter <= (others => '0');
            else
                counter <= counter + 1;
                if counter = x"FFFFF" then
                    stable <= sync(1);
                end if;
            end if;
        end if;
    end process;
    btn_out <= stable;
end Behavioral;
