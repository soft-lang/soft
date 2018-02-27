CREATE OR REPLACE FUNCTION LLVMIR_Run(
_LLVMIR text,
_Data int[],
_Size int,
_Ptr int,
_STDOUTRemaining int,
OUT Data int[],
OUT Ptr int,
OUT Ret int,
OUT STDOUTBuffer int[],
OUT STDOUTRemaining int
)
RETURNS RECORD
LANGUAGE plpython3u
AS $$
from ctypes import CFUNCTYPE, c_int32, c_int8, POINTER, byref
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
    cfunc = CFUNCTYPE(c_int32, POINTER(c_int8), c_int32, POINTER(c_int32), POINTER(c_int8), POINTER(c_int32))(func_ptr)
    CData = np.asarray(_data, dtype=np.int8)
    CSize = c_int32(_size)
    CPtr = c_int32(_ptr)
    CSTDOUTBuffer = np.zeros((_stdoutremaining,), dtype=np.int8)
    CSTDOUTRemaining = c_int32(_stdoutremaining)
    Ret = cfunc(CData.ctypes.data_as(POINTER(c_int8)), CSize, byref(CPtr), CSTDOUTBuffer.ctypes.data_as(POINTER(c_int8)), byref(CSTDOUTRemaining))
    return (CData, CPtr.value, Ret, CSTDOUTBuffer, CSTDOUTRemaining.value)
$$;

/*

SELECT * FROM LLVMIR_Run(
_LLVMIR := (SELECT LLVMIR FROM LLVMIR),
_Data := array_fill(0,array[30000]),
_Ptr := 0
);

*/

