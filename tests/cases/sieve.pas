(* Целые числа от 2 до 100: решето Эратосфена.
   Программа взята из ../dispak/tests/pascal-monitor/pascal.b6 (эталон
   работоспособности Pascal-Monitor), адаптирована как тест PERSO. *)
program main (output);
var
    prime: array [2..100] of boolean;
    n, k: integer;
{
    (* Обнулим prime *)
    for n:=2 to 100 do
        prime [n] := true;

    (* Вычислим prime *)
    for n:=2 to 100 do
        if prime[n] then
            for k:=2 to trunc (100/n) do
                prime [n*k] := false;

    (* Печать prime *)
    for n:=2 to 100 do
        if prime[n] then
            write (n);
}.
