import Base: &, |

UInt(mv::Move) = mv.packed_move
(&)(mv::Move, x::UInt16) = UInt(mv) & x
(|)(mv::Move, x::UInt16) = UInt(mv) | x
from(mv::Move) = Square((mv & 0b0000_000000_111111) + 1)
to(mv::Move) = Square((mv & 0b0000_111111_000000) >> 6 + 1)
show(io::IO, mv::Move) = print(io, "$(from(mv)) => $(to(mv))")

promotion_num(::Type{Knight}) = 0
promotion_num(::Type{Bishop}) = 1
promotion_num(::Type{Rook}) = 2
promotion_num(::Type{Queen}) = 3
function Move(from::Square,
              to::Square,
              promotion::Type{T}) where {T<:Piece}
    (Move((UInt(from) - 1) +
          ((UInt(to) - 1) << 6) +
          (1 << 12) +
          (promotion_num(promotion) << 14)))
end

function promotion(mv::Move)
    x = mv & 0b1101_000000_000000
    if     x == 0b0001_000000_000000
        return Knight
    elseif x == 0b0101_000000_000000
        return Bishop
    elseif x == 0b1001_000000_000000
        return Rook
    elseif x == 0b1101_000000_000000
        return Queen
    else
        return nothing
    end
end

function double_pawn_push(mv::Move)
    x = mv & 0b1111_000000_000000
    x == 0b1000_000000_000000
end
