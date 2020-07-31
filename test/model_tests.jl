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
    @test (vec([UInt(CJ.Square(x * y)) for x in 'a':'h', y in '1':'8']) ==
           [n for n in 1:64])

    @test_throws AssertionError CJ.Square(-1)
    @test_throws AssertionError CJ.Square(65)
end

@testset "BitBoard Object" begin
    b0 = CJ.BitBoard(0)
    b1 = CJ.BitBoard(1)
    b2 = CJ.BitBoard(2)
    b3 = CJ.BitBoard(3)

    @test b1 ∪ b0 == b1
    @test b1 ∪ b2 == b3
    @test b1 ∩ b3 == b1
    @test b1 ∩ b2 == b0

    @test CJ.Square(1) ∈ b1
    @test CJ.Square(2) ∉ b1
    @test CJ.Square(1) ∉ b2
    @test CJ.Square(2) ∈ b2
    @test !any(CJ.Square(i) ∈ b0 for i in 1:64)

    @test string(b1) == """........
                           ........
                           ........
                           ........
                           ........
                           ........
                           ........
                           x......."""
    @test string(b2) == """........
                           ........
                           ........
                           ........
                           ........
                           ........
                           ........
                           .x......"""
end

@testset "Move object" begin
    m1 = CJ.Move(CJ.Square("a2"), CJ.Square("a3"))
    @test UInt(m1) == 0b0000_010000_001000
    @test CJ.from(m1) == CJ.Square("a2")
    @test CJ.to(m1) == CJ.Square("a3")
    @test string(m1) == "a2 => a3"

    m2 = CJ.Move(CJ.Square("a8"), CJ.Square("h1"))
    @test UInt(m2) == 0b0000_000111_111000
    @test CJ.from(m2) == CJ.Square("a8")
    @test CJ.to(m2) == CJ.Square("h1")
    @test string(m2) == "a8 => h1"

    m3 = CJ.Move(CJ.Square("c7"), CJ.Square("c8"), CJ.Bishop)
    @test UInt(m3) == 0b0101_111010_110010
    @test CJ.from(m3) == CJ.Square("c7")
    @test CJ.to(m3) == CJ.Square("c8")
    @test CJ.promotion(m3) == CJ.Bishop

    m4 = CJ.Move(CJ.Square("d7"), CJ.Square("d8"), CJ.Queen)
    @test UInt(m4) == 0b1101_111011_110011
    @test CJ.from(m4) == CJ.Square("d7")
    @test CJ.to(m4) == CJ.Square("d8")
    @test CJ.promotion(m4) == CJ.Queen
end

@testset "FEN conversion" begin
    @testset "FEN move" begin
        @test CJ.parse_fen_move("w") == CJ.White
        @test CJ.parse_fen_move("b") == CJ.Black
        @test_throws CJ.ParseError CJ.parse_fen_move("-")
    end
    @testset "FEN castling" begin
        @test CJ.parse_fen_castling("KQkq") == CJ.Castling(true, true, true, true)
        @test CJ.parse_fen_castling("Qkq") == CJ.Castling(false, true, true, true)
        @test CJ.parse_fen_castling("Kkq") == CJ.Castling(true, false, true, true)
        @test CJ.parse_fen_castling("KQq") == CJ.Castling(true, true, false, true)
        @test CJ.parse_fen_castling("KQk") == CJ.Castling(true, true, true, false)
        @test CJ.parse_fen_castling("-") == CJ.Castling(false, false, false, false)
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
        @test CJ.parse_fen_moves("0", "0") == (0, 0)
        @test CJ.parse_fen_moves("6", "12") == (6, 12)
        # TODO: these throw UndefVarError but the code doesn't???
        # @test_throws CJ.ParseError CJ.parse_fen_int("2", "-1")
        # @test_throws CJ.ParseError CJ.parse_fen_int("a", "10")
    end

    @testset "FEN board object" begin
    board_1_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    board_1 = CJ.ChessBoard(board_1_fen)
    @test CJ.pieces(board_1, CJ.White) == CJ.BitBoard(0x000000000000ffff)
    @test CJ.pieces(board_1, CJ.Black) == CJ.BitBoard(0xffff000000000000)
    @test CJ.pieces(board_1, CJ.Pawn) == CJ.BitBoard(0x00ff00000000ff00)
    @test CJ.pieces(board_1, CJ.Knight) == CJ.BitBoard(0x4200000000000042)
    @test CJ.pieces(board_1, CJ.Bishop) == CJ.BitBoard(0x2400000000000024)
    @test CJ.pieces(board_1, CJ.Rook) == CJ.BitBoard(0x8100000000000081)
    @test CJ.pieces(board_1, CJ.Queen) == CJ.BitBoard(0x0800000000000008)
    @test CJ.pieces(board_1, CJ.King, CJ.White) == CJ.Square("e1")
    @test CJ.pieces(board_1, CJ.King, CJ.Black) == CJ.Square("e8")
    @test CJ.color(board_1) == CJ.White
    @test CJ.castling(board_1) == CJ.Castling(true, true, true, true)
    @test CJ.en_passant(board_1) == CJ.Square(0)
    @test CJ.inaction(board_1) == 0
    @test CJ.move(board_1) == 1
    @test CJ.fen(board_1) == board_1_fen

    # Nolot P1
    board_2_fen = "r3qb1k/1b4p1/p2pr2p/3n4/Pnp1N1N1/6RP/1B3PP1/1B1QR1K1 w - - 3 20"
    board_2 = CJ.ChessBoard(board_2_fen)
    @test CJ.pieces(board_2, CJ.White) == CJ.BitBoard(0x0000000051c0625a)
    @test CJ.pieces(board_2, CJ.Black) == CJ.BitBoard(0xb142990806000000)
    @test CJ.pieces(board_2, CJ.Pawn) == CJ.BitBoard(0x0040890005806000)
    @test CJ.pieces(board_2, CJ.Knight) == CJ.BitBoard(0x0000000852000000)
    @test CJ.pieces(board_2, CJ.Bishop) == CJ.BitBoard(0x2002000000000202)
    @test CJ.pieces(board_2, CJ.Rook) == CJ.BitBoard(0x0100100000400010)
    @test CJ.pieces(board_2, CJ.Queen) == CJ.BitBoard(0x1000000000000008)
    @test CJ.pieces(board_2, CJ.King, CJ.White) == CJ.Square("g1")
    @test CJ.pieces(board_2, CJ.King, CJ.Black) == CJ.Square("h8")
    @test CJ.color(board_2) == CJ.White
    @test CJ.castling(board_2) == CJ.Castling(false, false, false, false)
    @test CJ.en_passant(board_2) == CJ.Square(0)
    @test CJ.inaction(board_2) == 3
    @test CJ.move(board_2) == 20
    @test CJ.fen(board_2) == board_2_fen

    end
end

@testset "Mailbox Conversion" begin
    board_1_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    board_1 = CJ.ChessBoard(board_1_fen)
    board_1_mb = CJ.to_mailbox(board_1)
    @test length(board_1_mb) == 32
    @test board_1_mb[CJ.Square("a1")] == (CJ.Rook, CJ.White)
    @test board_1_mb[CJ.Square("b2")] == (CJ.Pawn, CJ.White)
    @test get(board_1_mb, CJ.Square("c3"), nothing) == nothing

    board_2_fen = "r3qb1k/1b4p1/p2pr2p/3n4/Pnp1N1N1/6RP/1B3PP1/1B1QR1K1 w - - 0 1"
    board_2 = CJ.ChessBoard(board_2_fen)
    board_2_mb = CJ.to_mailbox(board_2)
    @test length(board_2_mb) == 25
    @test get(board_2_mb, CJ.Square("a1"), nothing) == nothing
    @test board_2_mb[CJ.Square("b2")] == (CJ.Bishop, CJ.White)
    @test board_2_mb[CJ.Square("e6")] == (CJ.Rook, CJ.Black)
end

end
