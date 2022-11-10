; ModuleID = 'main3.bc'
source_filename = "main3.cpp"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind readnone uwtable
define dso_local i32 @_Z9fibonaccii(i32 %0) local_unnamed_addr #0 {
  %2 = add i32 %0, -1
  %3 = icmp ult i32 %2, 2
  br i1 %3, label %.loopexit, label %.preheader

.preheader:                                       ; preds = %1, %.preheader
  %4 = phi i32 [ %10, %.preheader ], [ %2, %1 ]
  %5 = phi i32 [ %8, %.preheader ], [ %0, %1 ]
  %6 = phi i32 [ %9, %.preheader ], [ 1, %1 ]
  %7 = tail call i32 @_Z9fibonaccii(i32 %4)
  %8 = add nsw i32 %5, -2
  %9 = add nsw i32 %7, %6
  %10 = add i32 %5, -3
  %11 = icmp ult i32 %10, 2
  br i1 %11, label %.loopexit, label %.preheader

.loopexit:                                        ; preds = %.preheader, %1
  %12 = phi i32 [ 1, %1 ], [ %9, %.preheader ]
  ret i32 %12
}

attributes #0 = { nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 10.0.0-4ubuntu1 "}
