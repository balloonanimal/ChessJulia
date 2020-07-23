import Base: UInt, ~

##### Square Stuff
@inline UInt(sqr::Square) = sqr.sqr_idx
@inline rank(sqr::Square) = (UInt(sqr) - 1) ÷ 8 + 1
@inline file(sqr::Square) = (UInt(sqr) - 1) % 8 + 1

function show(io::IO, sqr::Square)
    print(io, ('a' + (file(sqr) - 1)) * ('1' + (rank(sqr) - 1)))
end

##### Piece Stuff
fancy_str(::Type{Pawn}, ::Type{White}) = "♙"
fancy_str(::Type{Knight}, ::Type{White}) = "♘"
fancy_str(::Type{Bishop}, ::Type{White}) = "♗"
fancy_str(::Type{Rook}, ::Type{White}) = "♖"
fancy_str(::Type{Queen}, ::Type{White}) = "♕"
fancy_str(::Type{King}, ::Type{White}) = "♔"
fancy_str(::Type{Pawn}, ::Type{Black}) = "♟"
fancy_str(::Type{Knight}, ::Type{Black}) = "♞"
fancy_str(::Type{Bishop}, ::Type{Black}) = "♝"
fancy_str(::Type{Rook}, ::Type{Black}) = "♜"
fancy_str(::Type{Queen}, ::Type{Black}) = "♛"
fancy_str(::Type{King}, ::Type{Black}) = "♚"

ascii_str(::Type{Pawn}, ::Type{White}) = "P"
ascii_str(::Type{Knight}, ::Type{White}) = "N"
ascii_str(::Type{Bishop}, ::Type{White}) = "B"
ascii_str(::Type{Rook}, ::Type{White}) = "R"
ascii_str(::Type{Queen}, ::Type{White}) = "Q"
ascii_str(::Type{King}, ::Type{White}) = "K"
ascii_str(::Type{Pawn}, ::Type{Black}) = "p"
ascii_str(::Type{Knight}, ::Type{Black}) = "n"
ascii_str(::Type{Bishop}, ::Type{Black}) = "b"
ascii_str(::Type{Rook}, ::Type{Black}) = "r"
ascii_str(::Type{Queen}, ::Type{Black}) = "q"
ascii_str(::Type{King}, ::Type{Black}) = "k"

##### Color Stuff
(~)(c::Type{T}) where {T<:Color} = c == White ? Black : White

##### ChessBoard Stuff
function fen(cb::ChessBoard)
    mb = to_mailbox(cb)
    s = ""
    for rank in 8:-1:1
        empties = 0
        for file in 1:8
            sqr = Square(rank, file)
            piece = get(mb, sqr, nothing)
            if piece ≠ nothing
                if empties > 0
                    s *= "$empties"
                    empties = 0
                end
                s *= ascii_str(piece...)
            else
                empties += 1
            end
        end
        if empties > 0
            s *= "$empties"
        end
        if rank ≠ 1
            s *= "/"
        else
            s *= " "
        end
    end
    s *= fen_metadata(cb)
    s
end

function fen_metadata(cb::ChessBoard)
    # move
    s = "$(cb.whose_move == White ? "w" : "b") "
    # castling
    if cb.castling == 0
        s *= "- "
    else
        s *= "$(cb.castling & 1 ≠ 0 ? "K" : "")"
        s *= "$(cb.castling & 2 ≠ 0 ? "Q" : "")"
        s *= "$(cb.castling & 4 ≠ 0 ? "k" : "")"
        s *= "$(cb.castling & 8 ≠ 0 ? "q" : "") "
    end
    # en passant
    s *= "$(cb.en_passant_sqr == nothing ? "-" : board_to_alg_sqr(cb.en_passant_sqr)) "
    # moves
    s *= "$(cb.half_move_count) $(cb.move_count)"
    s
end

struct ParseError <: Exception
    msg :: AbstractString
end

function ChessBoard(fen::AbstractString)
    split_fen = split(fen, " ")
    if length(split_fen) ≠ 6
        throw(ParseError("Malformed FEN"))
    end

    # boards
    boards = parse_fen_board(split_fen[1])

    # move
    move = parse_fen_move(split_fen[2])

    # castling
    castling = parse_fen_castling(split_fen[3])

    # en passant
    en_passant = parse_fen_en_passant(split_fen[4])

    # half move count
    half_move_count = parse_fen_int(split_fen[5])

    #  move count
    move_count = parse_fen_int(split_fen[6])

    ChessBoard(boards..., castling, move,
               en_passant, half_move_count, move_count)
end

function parse_fen_board(board_str::AbstractString)
    ranks = split(board_str, "/")
    if length(ranks) ≠ 8
        throw(ParseError("Board must have 8 ranks"))
    end

    w_pieces    = BitBoard(0)
    b_pieces    = BitBoard(0)
    pawns       = BitBoard(0)
    knights     = BitBoard(0)
    bishops     = BitBoard(0)
    rooks       = BitBoard(0)
    queens      = BitBoard(0)
    w_king      = nothing
    b_king      = nothing

    for rank in 8:-1:1
        file = 1
        for val in ranks[9 - rank]
            if file > 8
                throw(ParseError("Rank $rank does not have 8 files"))
            end
            if '1' ≤ val ≤ '8'
                file += val - '0'
                continue
            end
            square = Square(rank, file)
            if     val == 'p'
                b_pieces |= square
                pawns |= square
            elseif val == 'n'
                b_pieces |= square
                knights |= square
            elseif val == 'b'
                b_pieces |= square
                bishops |= square
            elseif val == 'r'
                b_pieces |= square
                rooks |= square
            elseif val == 'q'
                b_pieces |= square
                queens |= square
            elseif val == 'k'
                b_pieces |= square
                b_king = square
            elseif val == 'P'
                w_pieces |= square
                pawns |= square
            elseif val == 'N'
                w_pieces |= square
                knights |= square
            elseif val == 'B'
                w_pieces |= square
                bishops |= square
            elseif val == 'R'
                w_pieces |= square
                rooks |= square
            elseif val == 'Q'
                w_pieces |= square
                queens |= square
            elseif val == 'K'
                w_pieces |= square
                w_king = square
            else
                throw(ParseError("Invalid character"))
            end
            file += 1
        end
        if file != 9
            throw(ParseError("Ranks does not have 8 files"))
        end
    end
    if b_king == nothing || w_king == nothing
        throw(ParseError("Both sides need kings"))
    end
    (w_pieces, b_pieces, pawns, knights, bishops,
     rooks, queens, w_king, b_king)
end

function parse_fen_move(move_str::AbstractString)
    if move_str == "w"
        White
    elseif move_str == "b"
        Black
    else
        throw(ParseError("Active color must be either w or b"))
    end
end

function parse_fen_castling(castle_str::AbstractString)
    castling = 0
    if castle_str == "-"
        return castling
    end
    m = match(r"^(K?)(Q?)(k?)(q?)$", castle_str)
    if m == nothing
        throw(ParseError("Malformed Castling string"))
    end
    if m[1] != ""
        castling += 1
    end
    if m[2] != ""
        castling += 2
    end
    if m[3] != ""
        castling += 4
    end
    if m[4] != ""
        castling += 8
    end
    castling
end

function parse_fen_en_passant(en_passant_str::AbstractString)
    if en_passant_str == "-"
        return nothing
    end
    s = nothing
    try
        s = Square(en_passant_str)
    catch e
        throw(ParseError("En Passant square malformed"))
    end
    if rank(s) != 3 && rank(s) != 6
        throw(ParseError("Impossible En Passant square"))
    end
    s
end

function parse_fen_int(int_str::AbstractString)
    i = nothing
    try
        i = parse(Int64, int_str)
    catch e
        throw(ParseError("Move value malformed"))
    end
    if i < 0
        throw(ParseError("Impossible move value"))
    end
    i
end

function to_mailbox(cb::ChessBoard)
    # TODO: why doesn't this work?
    # mb = Dict{Square, Tuple{Type{T}, Type{S}}}() where {T <: Color, S <: Piece}
    mb = Dict{Square, Tuple{DataType, DataType}}()
    function no_dup_insert!(sqr::Square, color::Type{T},
                            piece::Type{S}) where {T <: Color, S <: Piece}
        other_piece = get(mb, sqr, nothing)
        if other_piece == nothing
            mb[sqr] = (color, piece)
        else
            throw(ParseError(
                "Chessboard has two pieces ($color, $piece) $other_piece in square $sqr"))
        end
    end

    board_color_pairs = ((cb.active_color, cb.our_pieces),
                         (~cb.active_color, cb.their_pieces))
    board_piece_pairs = ((Pawn, cb.pawns),
                         (Knight, cb.knights),
                         (Bishop, cb.bishops),
                         (Rook, cb.rooks),
                         (Queen, cb.queens))
    for si in 1:64
        sqr = Square(si)
        for (color, c_board) in board_color_pairs
            # there is not a piece of this color on this square
            if !c_board[sqr]
                continue
            end
            # there is a piece, what is it?
            for (piece, p_board) in board_piece_pairs
                # not this piece
                if !p_board[sqr]
                    continue
                end
                no_dup_insert!(sqr, color, piece)
            end
        end
    end
    no_dup_insert!(cb.our_king, cb.active_color, King)
    no_dup_insert!(cb.their_king, ~cb.active_color, King)
    mb
end

function Base.show(io::IO, cb::ChessBoard)
    mb = to_mailbox(cb)
    function piece(rank, file)
        sqr = Square(rank, file)
        p = get(mb, sqr, nothing)
        if p == nothing
            " "
        else
            fancy_str(p...)
        end
    end

    # board representation
    s = "  ┌───┬───┬───┬───┬───┬───┬───┬───┐\n"
    for rank in 8:-1:1
        s *= "$(rank) │"
        for file in 1:8
            s *= " $(piece(rank, file)) │"
        end
        if rank ≠ 1
            s *= "\n  ├───┼───┼───┼───┼───┼───┼───┼───┤\n"
        end
    end
    s *= "\n  └───┴───┴───┴───┴───┴───┴───┴───┘\n"
    s *= "    a   b   c   d   e   f   g   h\n"

    # additional info
    s *= "    " * fen_metadata(cb)
    print(io, s)
end
