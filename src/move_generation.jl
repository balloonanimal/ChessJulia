include("masks_magic.jl")

function pawn_moves_single(cb::ChessBoard, c::Color_T)
    pawns = pieces(cb, Pawn, c)
    shift = c == White ? 8 : -8
    promotion_mask = c == White ? BitBoard(0xff00000000000000) : BitBoard(0x00000000000000ff)
    pushed_pawns = (pawns << shift) - pieces(cb)
    promotion_pawns = pushed_pawns ∩ promotion_mask

    pushes = [Move(s >> shift, s) for s in pushed_pawns - promotion_pawns]
    knight_promotions = [Move(s >> shift, s, Knight) for s in promotion_pawns]
    bishop_promotions = [Move(s >> shift, s, Bishop) for s in promotion_pawns]
    rook_promotions = [Move(s >> shift, s, Rook) for s in promotion_pawns]
    queen_promotions = [Move(s >> shift, s, Queen) for s in promotion_pawns]
    [pushes; knight_promotions; bishop_promotions; rook_promotions; queen_promotions]
end

function pawn_moves_double(cb::ChessBoard, c::Color_T)
    pawns = pieces(cb, Pawn, c)
    shift = c == White ? 8 : -8
    unmoved_mask = c == White ? BitBoard(0x000000000000ff00) : BitBoard(0x00ff000000000000)
    blocker_mask = unmoved_mask << shift

    blocked_files = (pieces(cb) ∩ blocker_mask) >> shift
    pushable_pawns = (pawns ∩ unmoved_mask) - blocked_files
    pushed_pawns = (pushable_pawns << (2 * shift)) - pieces(cb)

    pushes = [Move(s >> (2 * shift), s) for s in pushed_pawns]
    pushes
end

function pawn_moves_attacks(cb::ChessBoard, c::Color_T)
    pawns = pieces(cb, Pawn, c)
    left_shift = c == White ? 7 : -9
    right_shift = c == White ? 9 : -7
    # left
    not_left_pawns = pawns ∩ BitBoard(0xfefefefefefefefe)
    left_attack_pawns = (not_left_pawns << left_shift) ∩ pieces(cb, !c)
    left_attacks = [Move(s >> left_shift, s) for s in left_attack_pawns]
    # right
    not_right_pawns = pawns ∩ BitBoard(0x7f7f7f7f7f7f7f7f)
    right_attack_pawns = (not_right_pawns << right_shift) ∩ pieces(cb, !c)
    right_attacks = [Move(s >> right_shift, s) for s in right_attack_pawns]
    [left_attacks; right_attacks]
end

function pawn_moves(cb::ChessBoard, c::Color_T)
    [pawn_moves_single(cb, c);
     pawn_moves_double(cb, c);
     pawn_moves_attacks(cb, c)]
end

function king_moves(cb::ChessBoard, c::Color_T)
    our_king = pieces(cb, King, c)
    our_pieces = pieces(cb, c)
    moved_kings = MASKS_AND_MAGIC.king_attacks[UInt(our_king)] - our_pieces
    king_moves = [Move(our_king, s) for s in moved_kings]
end

function knight_moves(cb::ChessBoard, c::Color_T)
    our_knights = pieces(cb, Knight, c)
    our_pieces = pieces(cb, c)
    knight_moves = []
    for s in our_knights
        moved_knights = MASKS_AND_MAGIC.knight_attacks[UInt(s)]
        append!(knight_moves, [Move(s, m) for m in moved_knights - our_pieces])
    end
    knight_moves
end

function magic_lookup(s::Square, blockers::BitBoard, ::Type{Bishop})
    blocker_mask = MASKS_AND_MAGIC.bishop_blocker_masks[UInt(s)]
    magic = MASKS_AND_MAGIC.bishop_magics[UInt(s)]
    shift = MASKS_AND_MAGIC.bishop_shifts[UInt(s)]
    attacks = MASKS_AND_MAGIC.bishop_attacks[UInt(s)]
    relevant_blockers = blocker_mask ∩ blockers
    hash = (UInt(relevant_blockers) * magic) >> shift
    attacks[hash + 1]
end

function bishop_moves(cb::ChessBoard, c::Color_T)
    our_bishops = pieces(cb, Bishop, c)
    all_pieces = pieces(cb)
    our_pieces = pieces(cb, c)
    bishop_moves = []
    for s in our_bishops
        bishop_attacks = magic_lookup(s, all_pieces, Bishop)
        append!(bishop_moves, [Move(s, m) for m in bishop_attacks - our_pieces])
    end
    bishop_moves
end

function magic_lookup(s::Square, blockers::BitBoard, ::Type{Rook})
    blocker_mask = MASKS_AND_MAGIC.rook_blocker_masks[UInt(s)]
    magic = MASKS_AND_MAGIC.rook_magics[UInt(s)]
    shift = MASKS_AND_MAGIC.rook_shifts[UInt(s)]
    attacks = MASKS_AND_MAGIC.rook_attacks[UInt(s)]
    relevant_blockers = blocker_mask ∩ blockers
    hash = (UInt(relevant_blockers) * magic) >> shift
    attacks[hash + 1]
end

function rook_moves(cb::ChessBoard, c::Color_T)
    our_rooks = pieces(cb, Rook, c)
    all_pieces = pieces(cb)
    our_pieces = pieces(cb, c)
    rook_moves = []
    for s in our_rooks
        rook_attacks = magic_lookup(s, all_pieces, Rook)
        append!(rook_moves, [Move(s, m) for m in rook_attacks - our_pieces])
    end
    rook_moves
end

function queen_moves(cb::ChessBoard, c::Color_T)
    our_queens = pieces(cb, Queen, c)
    all_pieces = pieces(cb)
    our_pieces = pieces(cb, c)
    queen_moves = []
    for s in our_queens
        bishop_attacks = magic_lookup(s, all_pieces, Bishop)
        append!(queen_moves, [Move(s, m) for m in bishop_attacks - our_pieces])
        rook_attacks = magic_lookup(s, all_pieces, Rook)
        append!(queen_moves, [Move(s, m) for m in rook_attacks - our_pieces])
    end
    queen_moves
end

function moves(cb::ChessBoard, c::Color_T)::Array{Move, 1}
    [pawn_moves(cb, c);
     king_moves(cb, c);
     knight_moves(cb, c);
     bishop_moves(cb, c);
     rook_moves(cb, c);
     queen_moves(cb, c)]
end
moves(cb::ChessBoard) = moves(cb, color(cb))

# FIXME: don't do this. This function is the least possible efficient way to
# check legality. should be one of the first attempts for optimization
# START JANK
function legal(cb::ChessBoard, mv::Move)
    from_sqr, to_sqr = from(mv), to(mv)
    p1 = piece_on(cb, from_sqr)
    p1 = piece_on(cb, to_sqr)
    @assert p1 ≠ nothing && p1[2] == color(cb)
    @assert p2 == nothing || p2[2] == !color(cb)
    new_cb = make_move(cb, mv)
    # TODO: need to check much more than this
    !incheck(new_cb, cb.active_color)
end

function incheck(cb::ChessBoard, color::Color_T)
    new_moves = moves(cb)
    king = pieces(cb, King, color)
    for mv_ in new_moves
        if to(mv_) == king
            return true
        end
    end
    false
end
# END JANK

function perft(cb::ChessBoard, depth::Integer; pretty=false, pretty_depth=1)
    if pretty
        n, children = _perft_pretty(cb, depth, pretty_depth)
        println("$n")
        println("==========")
        _print_perft_pretty(children)
        return n
    else
        _perft(cb, depth)
    end
end

function _perft(cb::ChessBoard, depth::Integer)
    nodes = 0
    plegal_moves = moves(cb)
    for mv in plegal_moves
        new_cb = make_move(cb, mv)
        if !incheck(new_cb, cb.active_color)
            if depth==1
                nodes += 1
            else
                nodes += perft(new_cb, depth - 1)
            end
        end
    end
    nodes
end

function _perft_pretty(cb::ChessBoard, depth::Integer, pretty_depth::Integer)
    if depth == 0
        return (1, [])
    end
    if pretty_depth == 0
        return (_perft(cb, depth), [])
    end
    plegal_moves = moves(cb)
    tree = []
    for mv in plegal_moves
        new_cb = make_move(cb, mv)
        if !incheck(new_cb, cb.active_color)
            n, children = _perft_pretty(new_cb, depth - 1, pretty_depth - 1)
            push!(tree, (PGN(mv, cb), n, children))
        end
    end
    (sum(c[2] for c in tree), tree)
end

function _print_perft_pretty(tree; level=0)
    prefix = "  "^level
    for (mov, n, children) in tree
        println("$prefix$mov: $n")
        if children ≠ []
            _print_perft_pretty(children, level=level+1)
        end
    end
end
