@testset "Model" begin

@testset "FEN conversion" begin
    board_1_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    board_1 = CJ.Model.ChessBoard(board_1_fen)
    @test board_1.w_pawns.board == 0x000000000000ff00
    @test board_1.w_knights.board == 0x0000000000000042
    @test board_1.w_bishops.board == 0x0000000000000024
    @test board_1.w_rooks.board == 0x0000000000000081
    @test board_1.w_queens.board == 0x0000000000000008
    @test board_1.w_kings.board == 0x0000000000000010
    @test board_1.whose_move == 0
    @test board_1.w_castle == 3
    @test board_1.b_castle == 3
    @test board_1.en_passant_sqr == nothing
    @test board_1.half_move_count == 0
    @test board_1.move_count == 1

    board_2_fen = "2kr1b1r/pp1q1ppp/2n2n2/6B1/2PpN1b1/P7/1P3PPP/2RBK1NR b K c3 0 10"
    board_2 = CJ.Model.ChessBoard(board_2_fen)
    @test board_2.w_pawns.board == 0x000000000401e200
    @test board_2.w_knights.board == 0x0000000010000040
    @test board_2.w_bishops.board == 0x0000004000000008
    @test board_2.w_rooks.board == 0x0000000000000084
    @test board_2.w_queens.board == 0x0000000000000000
    @test board_2.w_kings.board == 0x0000000000000010
    @test board_2.whose_move == 1
    @test board_2.w_castle == 2
    @test board_2.b_castle == 0
    @test board_2.en_passant_sqr.board == 0x0000000000040000
    @test board_2.half_move_count == 0
    @test board_2.move_count == 10
end

end
