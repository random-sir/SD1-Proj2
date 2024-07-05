---------------------------------------------------------------------
------------------------------ TESTBENCH ----------------------------
---------------------------------------------------------------------

-- NOTA: Se for executar no EDA Playground, não use flags de compilação.
-- Em particular, o flag --std=08 (no import, no make e no run, mas *não*
-- no simulator) libera suporte a alguns comandos extras, (e.g., to_string),
-- que não necessariamente estão liberados no Judge.

library ieee;
use ieee.numeric_bit.all;

entity testbench is
end entity;

architecture tb of testbench is

  -- Component to be tested
  component uart is
    port (
      dado         : in  bit_vector(7 downto 0);
      start        : in  bit;
      TX           : out bit;
      ok           : out bit;
      clock, reset : in  bit);
  end component uart;

  -- Declaration of signals
  signal clk_in, rst_in : bit                    := '0';
  signal dado_in        : bit_vector(7 downto 0) := "01100101";
  signal start_in       : bit;
  signal TX_out         : bit;
  signal ok_out         : bit;


  constant clockPeriod   : time := 1 ns;  -- clock period
  signal keep_simulating : bit  := '0';   -- ao colocar em '0': interrompe simulação

begin
  -- Clock generator: clock runs while 'keep_simulating', with given
  -- period. When keep_simulating = '0', clock stops and so do the event
  -- simulation
  clk_in <= (not clk_in) and keep_simulating after clockPeriod/2;

  -- Connect DUT (Device Under Test)
  dut : uart
    port map(dado_in,
             start_in,
             TX_out,
             ok_out,
             clk_in,
             rst_in);

  stimulus : process is
    ---------------- Como são vários testes, vamos fazer um record array --------------
    type pattern_type is record
      --  The inputs of the circuit.
      --reset : bit;
      --dado   : bit_vector(7 downto 0);
      start : bit;
      --  The expected outputs of the circuit.
      TX    : bit;
      ok    : bit;
    end record;


    --  The patterns to apply.
    type pattern_array is array (natural range <>) of pattern_type;
    constant patterns : pattern_array :=
      (
        ('1', '0', '0'),
        ('1', '1', '0'),
        ('0', '0', '0'),
        ('0', '1', '0'),
        ('0', '0', '0'),
        ('0', '0', '0'),
        ('0', '1', '0'),
        ('0', '1', '0'),
        ('0', '0', '0'),
        ('0', '1', '0'),
        ('0', '1', '0'),
        ('0', '0', '0'),
        ('0', '1', '1')
        );

  begin

    assert false report "Simulation start" severity note;
    keep_simulating <= '1';


    --  Verifica cada pattern
    for k in patterns'range loop

      --  Fornece as entrada
      -- rst_in <= patterns(k).reset;
      start_in <= patterns(k).start;

      --  Espera até a atualização da UC
      wait until rising_edge(clk_in);

      --  Espera até a atualização da FD
      wait until falling_edge(clk_in);
      wait for clockPeriod/4;

      --  Verifica as saídas.
      assert (TX_out = patterns(k).TX) and
        (ok_out = patterns(k).ok)
        report "Teste " & integer'image(k) & " > "
        & "ok:" & bit'image(ok_out) & " (obtido), "
        & bit'image(patterns(k).ok) & " (esperado); "
        & "TX:" & bit'image(TX_out) & " (obtido), "
        & bit'image(patterns(k).TX) & " (esperado)."
-------------------------------------------------------------------------------------------------
-- NO EDA PLayground: fica liberado no GHDL com o flag --std=08 (no import, no make e no run,
-- mas *não* no simulator). Porém, pode não estar liberado no Judge: melhor evitar...
-------------------------------------------------------------------------------------------------
--                  & "Combo: " & to_string(combo_out) & " (obtido), "
--                  & to_string(patterns(k).combo) & " (esperado); "
--                  & "Score: " & to_string(score_out) & " (obtido), "
--                  & to_string(patterns(k).score) & " (esperado)."
-------------------------------------------------------------------------------------------------
        severity error;
    end loop;


    assert false report "Simulation end" severity note;
    keep_simulating <= '0';

    wait;                               -- end of simulation
  end process;


end architecture;
