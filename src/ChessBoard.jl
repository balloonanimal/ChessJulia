import Base: UInt, !, <<, >>

##### Square Stuff
@inline UInt(sqr::Square) = sqr.sqr_idx
@inline rank(sqr::Square) = (UInt(sqr) - 0x1) ÷ 0x8 + 0x1
@inline file(sqr::Square) = (UInt(sqr) - 0x1) % 0x8 + 0x1

function show(io::IO, sqr::Square)
    print(io, ('a' + (file(sqr) - 1)) * ('1' + (rank(sqr) - 1)))
end

# @inline flip(sqr::Square) = Square(UInt(sqr) ⊻ 56)
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

ascii_str(p::Piece_T) = ascii_str(p, White)
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
(!)(::Type{White}) = Black
(!)(::Type{Black}) = White

##### Castling Stuff
castling(c::Castling, ::Type{King}, ::Type{White})  = c.data & 0b0001 ≠ 0
castling(c::Castling, ::Type{Queen}, ::Type{White}) = c.data & 0b0010 ≠ 0
castling(c::Castling, ::Type{King}, ::Type{Black})  = c.data & 0b0100 ≠ 0
castling(c::Castling, ::Type{Queen}, ::Type{Black})  = c.data & 0b1000 ≠ 0
function show(io::IO, c::Castling)
    s  = ""
    s *= "$(castling(c, King, White)  ? "K" : "")"
    s *= "$(castling(c, Queen, White) ? "Q" : "")"
    s *= "$(castling(c, King, Black)  ? "k" : "")"
    s *= "$(castling(c, Queen, Black) ? "q" : "")"
    print(io, s == "" ? "-" : s)
end

##### ChessBoard Stuff
## getters
pieces(cb::ChessBoard, ::Type{White}) = cb.white_pieces
pieces(cb::ChessBoard, ::Type{Black}) = cb.black_pieces
pieces(cb::ChessBoard, ::Type{Pawn}) = cb.pawns
pieces(cb::ChessBoard, ::Type{Knight}) = cb.knights
pieces(cb::ChessBoard, ::Type{Bishop}) = cb.bishops
pieces(cb::ChessBoard, ::Type{Rook}) = cb.rooks
pieces(cb::ChessBoard, ::Type{Queen}) = cb.queens
pieces(cb::ChessBoard, ::Type{King}) = pieces(cb, King, White) ∪ piece(cb, King, Black)
pieces(cb::ChessBoard, ::Type{King}, ::Type{White}) = cb.white_king
pieces(cb::ChessBoard, ::Type{King}, ::Type{Black}) = cb.black_king
pieces(cb::ChessBoard, p::Piece_T, c::Color_T) = pieces(cb, p) ∩ pieces(cb, c)
pieces(cb::ChessBoard, c::Color_T, p::Piece_T) = pieces(cb, p, c)
pieces(cb::ChessBoard) = pieces(cb, White) ∪ pieces(cb, Black)

color(cb::ChessBoard)::Color_T = cb.active_color

castling(cb::ChessBoard) = cb.castling
castling(cb::ChessBoard, ::Type{King}, c::Color_T) = castling(castling(cb), King, c)
castling(cb::ChessBoard, ::Type{Queen}, c::Color_T) = castling(castling(cb), Queen, c)

en_passant(cb::ChessBoard) = cb.en_passant_sqr

inaction(cb::ChessBoard) = cb.half_move_count
move(cb::ChessBoard) = cb.move_count

## setters
function set_pieces!(cb::ChessBoard, ::Type{White}, b::BitBoard)
    cb.white_pieces = b
end
function set_pieces!(cb::ChessBoard, ::Type{Black}, b::BitBoard)
    cb.black_pieces = b
end
function set_pieces!(cb::ChessBoard, ::Type{Pawn}, b::BitBoard)
    cb.pawns = b
end
function set_pieces!(cb::ChessBoard, ::Type{Knight}, b::BitBoard)
    cb.knights = b
end
function set_pieces!(cb::ChessBoard, ::Type{Bishop}, b::BitBoard)
    cb.bishops = b
end
function set_pieces!(cb::ChessBoard, ::Type{Rook}, b::BitBoard)
    cb.rooks = b
end
function set_pieces!(cb::ChessBoard, ::Type{Queen}, b::BitBoard)
    cb.queens = b
end
function set_pieces!(cb::ChessBoard, ::Type{King}, ::Type{White}, s::Square)
    cb.white_king = s
end
function set_pieces!(cb::ChessBoard, ::Type{King}, ::Type{Black}, s::Square)
    cb.black_king = s
end

function set_color!(cb::ChessBoard, c::Color_T)
    cb.active_color = c
end

function set_castling!(cb::ChessBoard, c::Castling)
    cb.castling = c
end
function set_castling!(cb::ChessBoard, ::Type{King}, ::Type{White}, b::Bool)
    data = castling(cb).data
    set_castling!(b ? Castling(data | 0b0001) : Castling(data & 0b1110))
end
function set_castling!(cb::ChessBoard, ::Type{Queen}, ::Type{White}, b::Bool)
    data = castling(cb).data
    set_castling!(b ? Castling(data | 0b0010) : Castling(data & 0b1101))
end
function set_castling!(cb::ChessBoard, ::Type{King}, ::Type{Black}, b::Bool)
    data = castling(cb).data
    set_castling!(b ? Castling(data | 0b0100) : Castling(data & 0b1011))
end
function set_castling!(cb::ChessBoard, ::Type{Queen}, ::Type{Black}, b::Bool)
    data = castling(cb).data
    set_castling!(b ? Castling(data | 0b0100) : Castling(data & 0b0111))
end

function set_en_passant!(cb::ChessBoard, ep::Square)
    cb.en_passant_sqr = ep
end

function set_inaction!(cb::ChessBoard, m::Int64)
    cb.half_move_count = m
end
function set_move!(cb::ChessBoard, m::Int64)
    cb.move_count = m
end

function copy(cb::ChessBoard)
    ChessBoard(
        cb.white_pieces,
        cb.black_pieces,
        cb.pawns,
        cb.knights,
        cb.bishops,
        cb.rooks,
        cb.queens,
        cb.white_king,
        cb.black_king,
        cb.castling,
        cb.active_color,
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
    s = "$(color(cb) == White ? "w" : "b") "
    # castling
    s *= "$(castling(cb)) "
    # en passant
    s *= "$(en_passant(cb) == Square(0) ? "-" : en_passant(cb)) "
    # moves
    s *= "$(inaction(cb)) $(move(cb))"
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
    board_cb = parse_fen_board(split_fen[1])

    # move
    active_color = parse_fen_move(split_fen[2])

    # castling
    castling = parse_fen_castling(split_fen[3])

    # en passant
    ep = parse_fen_en_passant(split_fen[4])

    # half move count
    inaction, move = parse_fen_moves(split_fen[5], split_fen[6])

    ChessBoard(
        board_cb.white_pieces,
        board_cb.black_pieces,
        board_cb.pawns,
        board_cb.knights,
        board_cb.bishops,
        board_cb.rooks,
        board_cb.queens,
        board_cb.white_king,
        board_cb.black_king,
        castling,
        active_color,
        ep,
        inaction,
        move)
end

function parse_fen_board(board_str::AbstractString)
    function piece(c::Char)
        if c == 'P' return (Pawn, White) end
        if c == 'N' return (Knight, White) end
        if c == 'B' return (Bishop, White) end
        if c == 'R' return (Rook, White) end
        if c == 'Q' return (Queen, White) end
        if c == 'K' return (King, White) end
        if c == 'p' return (Pawn, Black) end
        if c == 'n' return (Knight, Black) end
        if c == 'b' return (Bishop, Black) end
        if c == 'r' return (Rook, Black) end
        if c == 'q' return (Queen, Black) end
        if c == 'k' return (King, Black) end
        return nothing
    end

    cb = ChessBoard()
    ranks = split(board_str, "/")
    if length(ranks) ≠ 8
        throw(ParseError("Board must have 8 ranks"))
    end

    w_kings, b_kings = 0, 0
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
            s = Square(rank, file)
            p = piece(val)
            if p == nothing
                throw(ParseError("Invalid character"))
            end
            p_type, color = p
            if (p_type, color) == (King, White)
                set_pieces!(cb, King, White, s)
                w_kings += 1
            elseif (p_type, color) == (King, Black)
                set_pieces!(cb, King, Black, s)
                b_kings += 1
            else
                set_pieces!(cb, p_type, pieces(cb, p_type) ∪ s)
            end
            set_pieces!(cb, color, pieces(cb, color) ∪ s)
            file += 1
        end
        if file != 9
            throw(ParseError("Ranks does not have 8 files"))
        end
    end
    if b_kings ≠ 1 || w_kings ≠ 1
        throw(ParseError("Invalid number of kings w = $w_kings b = $b_kings"))
    end
    cb
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
    castling = [false, false, false, false]
    if castle_str == "-"
        return Castling(castling...)
    end
    m = match(r"^(K?)(Q?)(k?)(q?)$", castle_str)
    if m == nothing
        throw(ParseError("Malformed Castling string"))
    end
    if m[1] != ""
        castling[1] = true
    end
    if m[2] != ""
        castling[2] = true
    end
    if m[3] != ""
        castling[3] = true
    end
    if m[4] != ""
        castling[4] = true
    end
    Castling(castling...)
end

function parse_fen_en_passant(en_passant_str::AbstractString)
    if en_passant_str == "-"
        return Square(0)
    end
    try
        s = Square(en_passant_str)
        if rank(s) != 3 && rank(s) != 6
            throw(ParseError("Impossible En Passant square"))
        end
        return s
    catch e
        throw(ParseError("En Passant square malformed"))
    end
end

function parse_fen_moves(half_move_str::AbstractString, move_str::AbstractString)
    function parse_int(s)
        i = nothing
        try
            i = parse(Int64, s)
        catch e
            throw(ParseError("Move value malformed"))
        end
        if i < 0
            throw(ParseError("Impossible move value"))
        end
        i
    end
    parse_int(half_move_str), parse_int(move_str)
end

function piece_on(cb::ChessBoard, sqr::Square)
    if sqr == cb.white_king
        return (King, White)
    elseif sqr == cb.black_king
        return (King, Black)
    end

    for color in (White, Black)
        # there is not a piece of this color on this square
        if sqr ∉ pieces(cb, color)
            continue
        end
        # there is a piece, what is it?
        for piece in (Pawn, Knight, Bishop, Rook, Queen)
            # not this piece
            if sqr ∉ pieces(cb, piece)
                continue
            end
            return (piece, color)
        end
    end
    nothing
end

function to_mailbox(cb::ChessBoard)
    # flip to white's perspective
    # cb = cb.perspective == White ? copy(cb) : flip(cb)
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

function involved_pieces(cb::ChessBoard, mv::Move)
    p1 = piece_on(cb, from(mv))
    @assert p1 ≠ nothing
    p2 = piece_on(cb, to(mv))
    p1, p2
end

# NOTE: assumes move is legal
#       also checks for a piece on from sqr, maybe unchecked faster?
# TODO: check the speed of this
#       + might be worth making branchless
#         clear out every board instead of costly
#         piece lookup
# TODO: half-move-count
# TODO: promotions
# TODO: set en_passant
function make_move(cb::ChessBoard, mv::Move)
    new_board = copy(cb)
    from_sqr, to_sqr = from(mv), to(mv)
    (piece_1, color_1), p2 = involved_pieces(cb, mv)
    if piece_1 == King
        set_pieces!(new_board, King, color(new_board), to_sqr)
        set_pieces!(new_board, color(new_board), pieces(new_board, color(new_board)) ∪ to_sqr - from_sqr)
    else
        set_pieces!(new_board, piece_1,
                    pieces(new_board, piece_1) ∪ to_sqr - from_sqr)
        set_pieces!(new_board, color(new_board),
                    pieces(new_board, color(new_board)) ∪ to_sqr - from_sqr)
    end

    if p2 ≠ nothing
        piece_2, color_2 = p2
        @assert color_2 == !color(new_board)
        set_pieces!(new_board, piece_2,
                    pieces(new_board, piece_2) - to_sqr)
        set_pieces!(new_board, !color(new_board),
                    pieces(new_board, !color(new_board)) - to_sqr)
    end

    # TODO: implement
    if promotion(mv) ≠ nothing
        throw("Not implemented yet")
    end

    set_color!(new_board, !color(new_board))
    if color(new_board) == White
        set_move!(new_board, move(new_board) + 1)
    end
    new_board
end

# TODO: implement
# function move_piece!(cb::ChessBoard, from::Square, to::Square)
#     piece = piece_on(cb, from)
#     remove_piece!(cb, from)
#     add_piece!(cb, to, piece)
# end

# function _remove_piece!(cb::ChessBoard, from::Square)
#     set_pieces!(cb, White, pieces(cb, White) - from)
#     set_pieces!(cb, Black, pieces(cb, Black) - from)
#     set_pieces!(cb, Pawn, pieces(cb, Pawn) - from)
#     set_pieces!(cb, Bishop, pieces(cb, Bishop) - from)
# end

function disambiguate(mv::Move, cb::ChessBoard)
    mvs = moves(cb)
    from_sqr = from(mv)
    p, _ = piece_on(cb, from_sqr)
    conflicting_starts = []
    for mv_ in mvs
        if mv_ == mv
            continue
        end
        if to(mv_) == to(mv) && piece_on(cb, from(mv_))[1] == p
            push!(conflicting_starts, from(mv_))
        end
    end
    if length(conflicting_starts) == 0
        return :no_conflict
    end
    if all(file(from_sqr) ≠ file(s) for s in conflicting_starts)
        return :file
    end
    if all(rank(from_sqr) ≠ rank(s) for s in conflicting_starts)
        return :rank
    end
    return :both
end

# TODO: disambiguate between similar moves
function PGN(mv::Move, cb::ChessBoard)
    # cb_ = cb.perspective == White ? cb : flip(cb)
    # mv_ = cb.perspective == White ? mv : flip(mv)
    s = ""
    (from_piece, _), dest_piece = involved_pieces(cb, mv)
    if from_piece ≠ Pawn
        s *= ascii_str(from_piece, White)
    end

    disambiguation = disambiguate(mv, cb)
    if disambiguation == :file
        s *= string(from(mv))[1]
    elseif disambiguation == :rank
        s *= string(from(mv))[2]
    elseif disambiguation == :both
        s *= string(from(mv))
    end

    if dest_piece == nothing
        return s * string(to(mv))
    end
    piece_2, color_2 = dest_piece
    @assert color_2 ≠ cb.active_color
    if from_piece == Pawn
        s *= string(from(mv))[1]
    end
    s * "x" * string(to(mv))
end

function Move(pgn::AbstractString, cb::ChessBoard)
    grps = match(r"^([KNBRQ]?)([a-h]?)([1-8]?)(x?)([a-h][1-8])$", pgn)
    if grps == nothing
        throw("Invalid move string")
    end
    function piece(s)
        if s == "K" return King end
        if s == "N" return Knight end
        if s == "B" return Bishop end
        if s == "R" return Rook end
        if s == "Q" return Queen end
        if s == "" return Pawn end
        throw("Invalid piece string")
    end
    p = piece(grps[1])
    # to_sqr = (cb.perspective == White) ? Square(grps[5]) : flip(Square(grps[5]))
    to_sqr = Square(grps[5])
    # capture
    if grps[4] == "x"
        if piece_on(cb, to_sqr) == nothing
            throw("there is no piece to capture on $to_sqr")
        end
    else
        if piece_on(cb, to_sqr) ≠ nothing
            throw("move to $to_sqr must be a capture")
        end
    end

    # correct destination
    candidates = [m for m in moves(cb) if to(m) == to_sqr]
    if length(candidates) == 0
        throw("no valid moves going to that square")
    end

    # correct piece
    candidates = [m for m in candidates if piece_on(cb, from(m))[1] == p]
    if length(candidates) == 0
        throw("no valid moves involving $p")
    end

    if grps[2] ≠ ""
        print(candidates)
        candidates = [m for m in candidates if file(from(m)) == 'a' - grps[2][1] + 1]
        print(candidates)
        if length(candidates) == 0
            throw("no valid moves on the right file")
        end
    end
    if grps[3] ≠ ""
        candidates = [m for m in candidates if rank(from(m)) == '1' - grps[3][1] + 1]
        if length(candidates) == 0
            throw("no valid moves on the right rank")
        end
    end

    if length(candidates) == 1
        return candidates[1]
    elseif length(candidates) == 0
        throw("invalid move string")
    else
        throw("ambiguous notation - should never happen (report to dev)")
    end
end
