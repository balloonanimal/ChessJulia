import Base: UInt

##### Square Stuff
@inline UInt(sqr::Square) = sqr.sqr_idx
@inline rank(sqr::Square) = (UInt(sqr) - 0x1) ÷ 0x8 + 0x1
@inline file(sqr::Square) = (UInt(sqr) - 0x1) % 0x8 + 0x1

function show(io::IO, sqr::Square)
    print(io, ('a' + (file(sqr) - 1)) * ('1' + (rank(sqr) - 1)))
end

@inline flip(sqr::Square) = Square(UInt(sqr) ⊻ 56)
@inline (<<)(sqr::Square, i::Integer) = Square(UInt(sqr) + i)
@inline (>>)(sqr::Square, i::Integer) = Square(UInt(sqr) - i)

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
(-)(c::Type{White}) = Black
(-)(c::Type{Black}) = White

##### ChessBoard Stuff
board(cb::ChessBoard, c::Color_T) = c == cb.active_color ? :our_pieces : :their_pieces
board(::Type{Pawn}) = :pawns
board(::Type{Knight}) = :knights
board(::Type{Bishop}) = :bishops
board(::Type{Rook}) = :rooks
board(::Type{Queen}) = :queens
board(cb::ChessBoard, c::Color_T, ::Type{King}) = c == :active_color ? :our_king : :their_king

function copy(cb::ChessBoard)
    ChessBoard(
        cb.our_pieces,
        cb.their_pieces,
        cb.pawns,
        cb.knights,
        cb.bishops,
        cb.rooks,
        cb.queens,
        cb.our_king,
        cb.their_king,
        cb.castling,
        cb.active_color,
        cb.perspective,
        cb.en_passant_sqr,
        cb.half_move_count,
        cb.move_count)
end

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
    s = "$(cb.active_color == White ? "w" : "b") "
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
    s *= "$(cb.en_passant_sqr == nothing ? "-" : cb.en_passant_sqr) "
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

    cb = ChessBoard(boards..., castling, White, move,
                    en_passant, half_move_count, move_count)
    if cb.active_color == Black
        flip!(cb)
    end
    cb
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
                b_pieces = b_pieces ∪ square
                pawns = pawns ∪ square
            elseif val == 'n'
                b_pieces = b_pieces ∪ square
                knights = knights ∪ square
            elseif val == 'b'
                b_pieces = b_pieces ∪ square
                bishops = bishops ∪ square
            elseif val == 'r'
                b_pieces = b_pieces ∪ square
                rooks = rooks ∪ square
            elseif val == 'q'
                b_pieces = b_pieces ∪ square
                queens = queens ∪ square
            elseif val == 'k'
                b_pieces = b_pieces ∪ square
                b_king = square
            elseif val == 'P'
                w_pieces = w_pieces ∪ square
                pawns = pawns ∪ square
            elseif val == 'N'
                w_pieces = w_pieces ∪ square
                knights = knights ∪ square
            elseif val == 'B'
                w_pieces = w_pieces ∪ square
                bishops = bishops ∪ square
            elseif val == 'R'
                w_pieces = w_pieces ∪ square
                rooks = rooks ∪ square
            elseif val == 'Q'
                w_pieces = w_pieces ∪ square
                queens = queens ∪ square
            elseif val == 'K'
                w_pieces = w_pieces ∪ square
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

function piece_on(cb::ChessBoard, sqr::Square)
    if sqr == cb.our_king
        return (King, cb.active_color)
    elseif sqr == cb.their_king
        return (King, -cb.active_color)
    end

    board_color_pairs = ((cb.active_color, cb.our_pieces),
                         (-cb.active_color, cb.their_pieces))
    board_piece_pairs = ((Pawn, cb.pawns),
                         (Knight, cb.knights),
                         (Bishop, cb.bishops),
                         (Rook, cb.rooks),
                         (Queen, cb.queens))
    for (color, c_board) in board_color_pairs
        # there is not a piece of this color on this square
        if sqr ∉ c_board
            continue
        end
        # there is a piece, what is it?
        for (piece, p_board) in board_piece_pairs
            # not this piece
            if sqr ∉ p_board
                continue
            end
            return (piece, color)
        end
    end
    nothing
end

function to_mailbox(cb::ChessBoard)
    # flip to white's perspective
    cb = cb.perspective == White ? copy(cb) : flip(cb)
    # TODO: why doesn't this work?
    # mb = Dict{Square, Tuple{Type{T}, Type{S}}}() where {T <: Color, S <: Piece}
    mb = Dict{Square, Tuple{DataType, DataType}}()
    function no_dup_insert!(sqr::Square, piece::Piece_T, color::Color_T)
        other_piece = get(mb, sqr, nothing)
        if other_piece == nothing
            mb[sqr] = (piece, color)
        else
            throw(ParseError(
                "Chessboard has two pieces ($color, $piece) $other_piece in square $sqr"))
        end
    end

    for si in 1:64
        sqr = Square(si)
        piece = piece_on(cb, sqr)
        if piece ≠ nothing
            no_dup_insert!(sqr, piece[1], piece[2])
        end
    end
   
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


# NOTE: assumes move is legal
#       also checks for a piece on from sqr, maybe unchecked faster?
# TODO: check the speed of this
#       + might be worth making branchless
#         clear out every board instead of costly
#         piece lookup
function make_move(cb::ChessBoard, mv::Move)
    new_board = copy(cb)
    from_sqr, to_sqr = from(mv), to(mv)
    p1 = piece_on(cb, from_sqr)
    p2 = piece_on(cb, to_sqr)

    if p1 == nothing
        # TODO: replace generic throw
        throw("No piece to move!")
    end
    piece_1, color_1 = p1
    if piece_1 == King
        new_board.our_king = to_sqr
        new_board.our_pieces = (new_board.our_pieces ∪ to_sqr) - from_sqr
    else
        _remove_piece!(new_board, from_sqr, piece_1, color_1)
        _add_piece!(new_board, to_sqr, piece_1, color_1)
    end

    if p2 ≠ nothing
        piece_2, color_2 = p2
        _remove_piece!(new_board, to_sqr, piece_2, color_2)
    end

    # TODO: implement
    if promotion(mv) ≠ nothing
        throw("Not implemented yet")
    end

    _switch_turn!(new_board)
    new_board
end

# NOTE: should never be called with King, assertion is internal logic
function _add_piece!(cb::ChessBoard, sqr::Square,
                     piece::Piece_T, color::Color_T)
    @assert piece ≠ King
    piece_board = board(piece)
    setproperty!(cb, piece_board, getproperty(cb, piece_board) ∪ sqr)
    color_board = board(cb, color)
    setproperty!(cb, color_board, getproperty(cb, color_board) ∪ sqr)
    nothing
end

# NOTE: should never be called with King, assertion is internal logic
function _remove_piece!(cb::ChessBoard, sqr::Square,
                        piece::Piece_T, color::Color_T)
    @assert piece ≠ King
    piece_board = board(piece)
    setproperty!(cb, piece_board, getproperty(cb, piece_board) - sqr)
    color_board = board(cb, color)
    setproperty!(cb, color_board, getproperty(cb, color_board) - sqr)
    nothing
end


function _switch_turn!(cb::ChessBoard)
    cb.active_color = -cb.active_color
    cb.our_pieces, cb.their_pieces = cb.their_pieces, cb.our_pieces
    cb.our_king, cb.their_king = cb.their_king, cb.our_king
    flip!(cb)
    cb.move_count += 1
end

function flip!(cb::ChessBoard)
    cb.our_pieces = flip(cb.our_pieces)
    cb.their_pieces = flip(cb.their_pieces)
    cb.pawns = flip(cb.pawns)
    cb.knights = flip(cb.knights)
    cb.bishops = flip(cb.bishops)
    cb.rooks = flip(cb.rooks)
    cb.queens = flip(cb.queens)
    cb.our_king = flip(cb.our_king)
    cb.their_king = flip(cb.their_king)
    cb.castling = ((cb.castling & 0b1100) >> 2) | ((cb.castling & 0b0011) << 2)
    cb.en_passant_sqr = cb.en_passant_sqr == nothing ? nothing : flip(cb.en_passant_sqr)
    cb.perspective = -cb.perspective
end

function flip(cb::ChessBoard)
    new_cb = copy(cb)
    flip!(new_cb)
    new_cb
end
