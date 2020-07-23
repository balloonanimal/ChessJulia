@testset "Model" begin

@testset "Square Object" begin
    s1 = CJ.Square(1)
    @test CJ.rank(s1) == 1
    @test CJ.file(s1) == 1
    @test string(s1) == "a1"
    @test CJ.BitBoard(s1) == CJ.BitBoard(0x0000000000000001)

    s2 = CJ.Square("d3")
    @test CJ.rank(s2) == 3
    @test CJ.file(s2) == 4
    @test UInt(s2) == 20
    @test CJ.BitBoard(s2) == CJ.BitBoard(0x0000000000080000)

    @test ([string(CJ.Square(n)) for n in 1:64] ==
           vec([x * y for x in 'a':'h', y in '1':'8']))

    @test_throws AssertionError CJ.Square(-1)
    @test_throws AssertionError CJ.Square(0)
    @test_throws AssertionError CJ.Square(65)
end

@testset "BitBoard Object" begin
    b0 = CJ.BitBoard(0)
    b1 = CJ.BitBoard(1)
    b2 = CJ.BitBoard(2)
    b3 = CJ.BitBoard(3)

    @test b1 | b0 == b1
    @test b1 | b2 == b3
    @test b1 & b3 == b1
    @test b1 & b2 == b0

    @test b1[CJ.Square(1)]
    @test !b1[CJ.Square(2)]
    @test !b2[CJ.Square(1)]
    @test b2[CJ.Square(2)]
    @test !any(b0[CJ.Square(i)] for i in 1:64)

    @test string(b1) == "0000000000000000000000000000000000000000000000000000000000000001"
    @test string(b2) == "0000000000000000000000000000000000000000000000000000000000000010"
end


@testset "FEN conversion" begin
    @testset "FEN move" begin
        @test CJ.parse_fen_move("w") == CJ.White
        @test CJ.parse_fen_move("b") == CJ.Black
        @test_throws CJ.ParseError CJ.parse_fen_move("-")
    end
    @testset "FEN castling" begin
        @test CJ.parse_fen_castling("KQkq") == 8 + 4 + 2 + 1
        @test CJ.parse_fen_castling("Qkq") == 8 + 4 + 2
        @test CJ.parse_fen_castling("Kkq") == 8 + 4 + 1
        @test CJ.parse_fen_castling("KQk") == 4 + 2 + 1
        @test CJ.parse_fen_castling("KQq") == 8 + 2 + 1
        @test CJ.parse_fen_castling("-") == 0
        @test_throws CJ.ParseError CJ.parse_fen_castling("kqKq")
        @test_throws CJ.ParseError CJ.parse_fen_castling("abc")
    end
    @testset "FEN en passant" begin
        @test CJ.parse_fen_en_passant("a3") == CJ.Square("a3")
        @test CJ.parse_fen_en_passant("d6") == CJ.Square("d6")
        @test_throws CJ.ParseError CJ.parse_fen_en_passant("c2")
        @test_throws CJ.ParseError CJ.parse_fen_en_passant("2a")
    end
    @testset "FEN move count" begin
        @test CJ.parse_fen_int("12") == 12
        @test_throws CJ.ParseError CJ.parse_fen_int("-1")
        @test_throws CJ.ParseError CJ.parse_fen_int("a")
    end

    @testset "FEN board object" begin
    board_1_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    board_1 = CJ.ChessBoard(board_1_fen)
    @test board_1.our_pieces == CJ.BitBoard(0x000000000000ffff)
    @test board_1.their_pieces == CJ.BitBoard(0xffff000000000000)
    @test board_1.pawns == CJ.BitBoard(0x00ff00000000ff00)
    @test board_1.knights == CJ.BitBoard(0x4200000000000042)
    @test board_1.bishops == CJ.BitBoard(0x2400000000000024)
    @test board_1.rooks == CJ.BitBoard(0x8100000000000081)
    @test board_1.queens == CJ.BitBoard(0x0800000000000008)
    @test board_1.our_king == CJ.Square("e1")
    @test board_1.their_king == CJ.Square("e8")
    @test board_1.active_color == CJ.White
    @test board_1.castling == 8 + 4 + 2 + 1
    @test board_1.en_passant_sqr == nothing
    @test board_1.half_move_count == 0
    @test board_1.move_count == 1
    # @test CJ.fen(board_1) == board_1_fen

    # Nolot P1
    board_2_fen = "r3qb1k/1b4p1/p2pr2p/3n4/Pnp1N1N1/6RP/1B3PP1/1B1QR1K1 w - - 0 1"
    board_2 = CJ.ChessBoard(board_2_fen)
    @test board_2.our_pieces == CJ.BitBoard(0x0000000051c0625a)
    @test board_2.their_pieces == CJ.BitBoard(0xb142990806000000)
    @test board_2.pawns == CJ.BitBoard(0x0040890005806000)
    @test board_2.knights == CJ.BitBoard(0x0000000852000000)
    @test board_2.bishops == CJ.BitBoard(0x2002000000000202)
    @test board_2.rooks == CJ.BitBoard(0x0100100000400010)
    @test board_2.queens == CJ.BitBoard(0x1000000000000008)
    @test board_2.our_king == CJ.Square("g1")
    @test board_2.their_king == CJ.Square("h8")
    @test board_2.active_color == CJ.White
    @test board_2.castling == 0
    @test board_2.en_passant_sqr == nothing
    @test board_2.half_move_count == 0
    @test board_2.move_count == 1
    # @test CJ.fen(board_2) == board_2_fen
    end
end

@testset "Mailbox Conversion" begin
    board_1_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    board_1 = CJ.ChessBoard(board_1_fen)
    board_1_mb = CJ.to_mailbox(board_1)
    @test length(board_1_mb) == 32
    @test board_1_mb[CJ.Square("a1")] == (CJ.White, CJ.Rook)
    @test board_1_mb[CJ.Square("b2")] == (CJ.White, CJ.Pawn)
    @test get(board_1_mb, CJ.Square("c3"), nothing) == nothing

    board_2_fen = "r3qb1k/1b4p1/p2pr2p/3n4/Pnp1N1N1/6RP/1B3PP1/1B1QR1K1 w - - 0 1"
    board_2 = CJ.ChessBoard(board_2_fen)
    board_2_mb = CJ.to_mailbox(board_2)
    @test length(board_2_mb) == 25
    @test get(board_2_mb, CJ.Square("a1"), nothing) == nothing
    @test board_2_mb[CJ.Square("b2")] == (CJ.White, CJ.Bishop)
    @test board_2_mb[CJ.Square("e6")] == (CJ.Black, CJ.Rook)
end

end
