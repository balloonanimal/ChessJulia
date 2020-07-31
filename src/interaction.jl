play_game() = play_game("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
function play_game(pgn::AbstractString)
    cb = ChessBoard(pgn)
    while true
        println(cb)
        print("Enter a move: ")
        mov_str = readline()
        mov = nothing
        while mov == nothing
            # FIXME: for debugging
            if mov_str == "print moves"
                movs = moves(cb)
                for m in movs
                    println(PGN(m, cb))
                end
                print("Enter a move: ")
                mov_str = readline()
            end

            try
                mov = Move(mov_str, cb)
            catch e
                println("Invalid move")
                print("Enter a move: ")
                mov_str = readline()
            end
        end
        cb = make_move(cb, mov)
    end
end
