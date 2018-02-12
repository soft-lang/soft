CREATE OR REPLACE FUNCTION LLVMIR_Run(
_LLVMIR text,
_Memory int[],
_DataPtr int,
OUT Memory int[],
OUT DataPtr int,
OUT ProgPtr int
)
RETURNS RECORD
LANGUAGE plpython3u
AS $$
from ctypes import CFUNCTYPE, c_int32, c_int8, POINTER, byref
import llvmlite.ir as ll
import llvmlite.binding as llvm
import numpy as np
llvm.initialize()
llvm.initialize_native_target()
llvm.initialize_native_asmprinter()

if __name__ == "__main__":
    features = llvm.get_host_cpu_features().flatten()
    llvm_module = llvm.parse_assembly(_llvmir)
    target = llvm.Target.from_default_triple()
    target_machine = target.create_target_machine(opt=3, features=features)
    engine = llvm.create_mcjit_compiler(llvm_module, target_machine)
    engine.finalize_object()
    func_ptr = engine.get_function_address("__llvmjit")

    cfunc = CFUNCTYPE(c_int32, POINTER(c_int8), POINTER(c_int32))(func_ptr)
    CMemory = np.asarray(_memory, dtype=np.int8)
    CDataPtr = c_int32(_dataptr)
    RetVal = cfunc(CMemory.ctypes.data_as(POINTER(c_int8)), byref(CDataPtr))
    return (CMemory, CDataPtr.value, RetVal)
$$;

/*

SELECT * FROM LLVMIR_Run(
_LLVMIR := (SELECT LLVMIR FROM LLVMIR),
_Memory := array_fill(0,array[30000]),
_DataPtr := 0
);

*/

