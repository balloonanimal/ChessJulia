include("masks_magic.jl")

function pawn_moves_single(cb::ChessBoard)
    our_pawns = cb.pawns ∩ cb.our_pieces
    pushed_pawns = (our_pawns << 8) - (cb.our_pieces ∪ cb.their_pieces)
    promotion_pawns = pushed_pawns ∩ BitBoard(0xff00000000000000)

    pushes = [Move(s >> 8, s) for s in pushed_pawns - promotion_pawns]
    knight_promotions = [Move(s >> 8, s, Knight) for s in promotion_pawns]
    bishop_promotions = [Move(s >> 8, s, Bishop) for s in promotion_pawns]
    rook_promotions = [Move(s >> 8, s, Rook) for s in promotion_pawns]
    queen_promotions = [Move(s >> 8, s, Queen) for s in promotion_pawns]
    [pushes; knight_promotions; bishop_promotions; rook_promotions; queen_promotions]
end

function pawn_moves_double(cb::ChessBoard)
    our_pushable_pawns = cb.pawns ∩ BitBoard(0x000000000000ff00) ∩ cb.our_pieces
    pushed_pawns = (our_pushable_pawns << 16) - (cb.our_pieces ∪ cb.their_pieces)

    pushes = [Move(s >> 16, s) for s in pushed_pawns]
    pushes
end

function pawn_moves_attacks(cb::ChessBoard)
    our_pawns = cb.pawns ∩ cb.our_pieces
    # left
    not_right_pawns = our_pawns ∩ BitBoard(0xfefefefefefefefe)
    right_attack_pawns = (not_right_pawns << 9) ∩ cb.their_pieces
    right_attacks = [Move(s >> 9, s) for s in right_attack_pawns]
    # right
    not_left_pawns = our_pawns ∩ BitBoard(0x7f7f7f7f7f7f7f7f)
    left_attack_pawns = (not_left_pawns << 7) ∩ cb.their_pieces
    left_attacks = [Move(s >> 7, s) for s in left_attack_pawns]
    [left_attacks; right_attacks]
end

function pawn_moves(cb::ChessBoard)
    [pawn_moves_single(cb);
     pawn_moves_double(cb);
     pawn_moves_attacks(cb)]
end

function king_moves(cb::ChessBoard)
    moved_kings = MASKS_AND_MAGIC.king_attacks[UInt(cb.our_king)] - cb.our_pieces
    king_moves = [Move(cb.our_king, s) for s in moved_kings]
end

function knight_moves(cb::ChessBoard)
    our_knights = cb.knights ∩ cb.our_pieces
    knight_moves = []
    for s in our_knights
        moved_knights = MASKS_AND_MAGIC.knight_attacks[UInt(s)]
        append!(knight_moves, [Move(s, m) for m in moved_knights - cb.our_pieces])
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

function bishop_moves(cb::ChessBoard)
    our_bishops = cb.bishops ∩ cb.our_pieces
    bishop_moves = []
    for s in our_bishops
        bishop_attacks = magic_lookup(s, cb.our_pieces ∪ cb.their_pieces, Bishop)
        append!(bishop_moves, [Move(s, m) for m in bishop_attacks - cb.our_pieces])
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

function rook_moves(cb::ChessBoard)
    our_rooks = cb.rooks ∩ cb.our_pieces
    rook_moves = []
    for s in our_rooks
        rook_attacks = magic_lookup(s, cb.our_pieces ∪ cb.their_pieces, Rook)
        append!(rook_moves, [Move(s, m) for m in rook_attacks - cb.our_pieces])
    end
    rook_moves
end

function queen_moves(cb::ChessBoard)
    our_queens = cb.queens ∩ cb.our_pieces
    queen_moves = []
    for s in our_queens
        bishop_attacks = magic_lookup(s, cb.our_pieces ∪ cb.their_pieces, Bishop)
        append!(queen_moves, [Move(s, m) for m in bishop_attacks - cb.our_pieces])
        rook_attacks = magic_lookup(s, cb.our_pieces ∪ cb.their_pieces, Rook)
        append!(queen_moves, [Move(s, m) for m in rook_attacks - cb.our_pieces])
    end
    queen_moves
end

function moves(cb::ChessBoard)::Array{Move, 1}
    [pawn_moves(cb);
     king_moves(cb);
     knight_moves(cb);
     bishop_moves(cb);
     rook_moves(cb);
     queen_moves(cb)]
end

# FIXME: don't do this. This function is the least possible efficient way to
# check legality. should be one of the first attempts for optimization
# START JANK
function legal(cb::ChessBoard, mv::Move)
    from_sqr, to_sqr = from(mv), to(mv)
    p1 = piece_on(cb, from_sqr)
    p1 = piece_on(cb, to_sqr)
    @assert p1 ≠ nothing && p1[2] == cb.active_color
    @assert p2 == nothing || p1[2] == -cb.active_color
    new_cb = make_move(cb, mv)
    # TODO: need to check much more than this
    !incheck(new_cb, cb.active_color)
end

function incheck(cb::ChessBoard, color::Color_T)
    new_moves = moves(cb)
    king = getproperty(cb, board(cb, color, King))
    for mv_ in new_moves
        if to(mv_) == king
            return true
        end
    end
    false
end
# END JANK

function perft(cb::ChessBoard, depth::Integer)
    if depth == 0
        return 1
    end
    nodes = 0
    plegal_moves = moves(cb)
    for mv in plegal_moves
        new_cb = make_move(cb, mv)
        if !incheck(new_cb, cb.active_color)
            nodes += perft(new_cb, depth - 1)
        end
    end
    nodes
end
