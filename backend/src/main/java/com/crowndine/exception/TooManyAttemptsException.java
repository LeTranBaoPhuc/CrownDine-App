package com.crowndine.exception;

public class TooManyAttemptsException extends RuntimeException {
    public TooManyAttemptsException() { super("Đã thử quá nhiều lần. Vui lòng chờ 5 phút trước khi thử lại."); }
}
