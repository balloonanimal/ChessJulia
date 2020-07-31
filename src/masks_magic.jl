# TODO: maybe return Bitboard(0) instead of nothing
step(s::Square, ::Type{UpLeft}) = (rank(s) == 8 || file(s) == 8) ? nothing : s << 9
step(s::Square, ::Type{Up}) = (rank(s) == 8) ? nothing : s << 8
step(s::Square, ::Type{UpRight}) = (rank(s) == 8 || file(s) == 1) ? nothing : s << 7
step(s::Square, ::Type{Right}) = (file(s) == 8) ? nothing : s << 1
step(s::Square, ::Type{Left}) = (file(s) == 1) ? nothing : s >> 1
step(s::Square, ::Type{DownRight}) = (rank(s) == 1 || file(s) == 8) ? nothing : s >> 7
step(s::Square, ::Type{Down}) = (rank(s) == 1) ? nothing : s >> 8
step(s::Square, ::Type{DownLeft}) = (rank(s) == 1 || file(s) == 1) ? nothing : s >> 9


function move_mask(s::Square, ::Type{King})
    moves = BitBoard(0)
    for direction in (UpLeft, Up, UpRight, Right,
                      Left, DownRight, Down, DownLeft)
        s_ = step(s, direction)
        if s_ ≠ nothing
            moves = moves ∪ s_
        end
    end
    moves
end

function move_mask(s::Square, ::Type{Knight})
    moves = BitBoard(0)
    function knight_move(s, steps)
        s_ = s
        for offset in steps
            s_ = step(s_, offset)
            if s_ == nothing
                return nothing
            end
        end
        s_
    end
    for move in ((Up, Up, Right),
                 (Up, Up, Left),
                 (Up, Right, Right),
                 (Up, Left, Left),
                 (Down, Right, Right),
                 (Down, Left, Left),
                 (Down, Down, Right),
                 (Down, Down, Left))
        s_ = knight_move(s, move)
        if s_ ≠ nothing
            moves = moves ∪ s_
        end
    end
    moves
end

function move_mask(s::Square, ::Type{Bishop}; blockers=BitBoard(0))
    mask = BitBoard(0)
    for offset in (UpRight, UpLeft, DownRight, DownLeft)
        s_ = step(s, offset)
        while s_ ≠ nothing
            mask = mask ∪ s_
            if s_ ∈ blockers
                break
            end
            s_ = step(s_, offset)
        end
    end
    mask
end

function move_mask(s::Square, ::Type{Rook}; blockers=BitBoard(0))
    mask = BitBoard(0)
    for offset in (Up, Right, Left, Down)
        s_ = step(s, offset)
        while s_ ≠ nothing
            mask = mask ∪ s_
            if s_ ∈ blockers
                break
            end
            s_ = step(s_, offset)
        end
    end
    mask
end


function blocker_mask(s::Square, ::Type{Bishop})
    move_mask(s, Bishop) ∩ BitBoard(0x007e7e7e7e7e7e00)
end

function blocker_mask(s::Square, ::Type{Rook})
    mask = move_mask(s, Rook)
    if rank(s) ≠ 1
        mask = mask ∩ BitBoard(0xffffffffffffff00)
    end
    if rank(s) ≠ 8
        mask = mask ∩ BitBoard(0x00ffffffffffffff)
    end
    if file(s) ≠ 1
        mask = mask ∩ BitBoard(0xfefefefefefefefe)
    end
    if file(s) ≠ 8
        mask = mask ∩ BitBoard(0x7f7f7f7f7f7f7f7f)
    end
    mask
end

function find_magics(s::Square, piece::Piece_T)
    # adapted from
    # https://www.chessprogramming.org/index.php?title=Looking_for_Magics
    @assert piece == Bishop || piece == Rook
    mask = blocker_mask(s, piece)
    bits = length(mask)

    blockers = Array{BitBoard}(undef, 2^bits)
    attacks = Array{BitBoard}(undef, 2^bits)
    used = Array{BitBoard}(undef, 2^bits)

    # go through every possible blocked board state that can result from
    # blocker_mask ∩ all_pieces
    # and precalculate attacks for them
    for (i, blocker_board) in enumerate(combinations(mask))
        blockers[i] = blocker_board
        attacks[i] = move_mask(s, piece, blockers=blocker_board)
    end

    # try a bunch of random magic numbers
    fewbit_rand() = rand(UInt64) & rand(UInt64) & rand(UInt64)
    function try_magic(magic::UInt64)
        # we want the magic to translate the mask values into the top row
        top_row = BitBoard((UInt(mask) * magic) & 0xff00000000000000)
        if length(top_row) < 6
            return nothing
        end
        fill!(used, BitBoard(0))
        for (blocker, attack) in zip(blockers, attacks)
            hash = (UInt(blocker) * magic) >> (64 - bits)
            if used[hash + 1] ≠ BitBoard(0) && used[hash + 1] ≠ attack
                # print("magic\n====\n$magic\nblocker\n====\n$blocker\nattack\n====\n$attack\nused[hash + 1]\n====\n$(used[hash + 1])\n")
                # throw("REMOVE ME")
                return nothing
            end
            used[hash + 1] = attack
        end
        magic
    end

    magic = fewbit_rand()
    while try_magic(magic) == nothing
        magic = fewbit_rand()
    end
    # @info "$s, $(ascii_str(piece, White)) = $magic"
    (mask, magic, bits, used)
end

# TODO: do bishop and rook need to be here?
# merge this with magic obj?
function MasksAndMagic()
    @info "Generating Move Masks"
    king_attacks = [move_mask(Square(s), King) for s in 1:64]
    knight_attacks = [move_mask(Square(s), Knight) for s in 1:64]
    @info "Generating Magic BitBoards"
    bishop_magic = [find_magics(Square(s), Bishop) for s in 1:64]
    bishop_blocker_masks = getindex.(bishop_magic, 1)
    bishop_magics = getindex.(bishop_magic, 2)
    bishop_shifts = 64 .- getindex.(bishop_magic, 3)
    bishop_attacks = getindex.(bishop_magic, 4)

    rook_magic = [find_magics(Square(s), Rook) for s in 1:64]
    rook_blocker_masks = getindex.(rook_magic, 1)
    rook_magics = getindex.(rook_magic, 2)
    rook_shifts = 64 .- getindex.(rook_magic, 3)
    rook_attacks = getindex.(rook_magic, 4)
    MasksAndMagic(
        king_attacks,
        knight_attacks,
        bishop_blocker_masks,
        bishop_magics,
        bishop_shifts,
        bishop_attacks,
        rook_blocker_masks,
        rook_magics,
        rook_shifts,
        rook_attacks)
end

MASKS_AND_MAGIC = MasksAndMagic()
