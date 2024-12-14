
(setq bdx 52)
(setq bdy 63)
(setq adx 97)
(setq ady 12)

(setq x (+ 10000000000000 4350))
(setq y (+ 10000000000000 10471))

(setq b (min
         (/ x bdx)
         (/ y bdy)))

(setq b ())

(setq b 100000000000)

(setq l (/ (- x (* b bdx)) adx))
(setq k (/ (- y (* b bdy)) ady))

(abs (- l k))

;; why the big difference?
;; how to choose b wisely
