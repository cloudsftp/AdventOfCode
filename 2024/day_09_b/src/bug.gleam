//fn checksum(files: List(File)) -> Int {
//  let #(sum, _) =
//    files
//    |> list.fold(#(0, 0), fn(acc, file) {
//      let #(sum, index) = acc
//      let #(id, size, space) = file
//
//      let delta =
//        sum + list.range(index, index + size - 1)
//        |> list.map(fn(index) { index * id })
//        |> int.sum
//
//      let sum = sum + delta
//
//      todo
//    })
//
//  sum
//}
