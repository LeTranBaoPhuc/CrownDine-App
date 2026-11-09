package com.crowndine.repository;

import com.crowndine.common.enums.EPaymentStatus;
import com.crowndine.common.enums.EPaymentTarget;
import com.crowndine.model.Payment;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long>, JpaSpecificationExecutor<Payment> {
    @org.springframework.transaction.annotation.Transactional
    default void updateCheckoutUrl(Long code, String url) {
        // Reload under a lock so a late create response cannot overwrite a paid webhook.
        Payment payment = findByCodeForUpdate(code).orElseThrow();
        payment.setCheckoutUrl(url);
        save(payment);
    }

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Payment p where p.code = :code")
    Optional<Payment> findByCodeForUpdate(@Param("code") Long code);
    Optional<Payment> findFirstByTargetAndReservationIdAndStatusOrderByIdDesc(EPaymentTarget target, Long id, EPaymentStatus status);
    Optional<Payment> findFirstByTargetAndOrderIdAndStatusOrderByIdDesc(EPaymentTarget target, Long id, EPaymentStatus status);

    Optional<Payment> findByCode(Long code);
    Optional<Payment> findFirstByOrderIdOrderByIdDesc(Long orderId);
    Optional<Payment> findFirstByReservationIdOrderByIdDesc(Long reservationId);

    //Các giao dịch CỌC đã THÀNH CÔNG của bàn
    List<Payment> findByTargetAndReservationIdAndStatus(EPaymentTarget ePaymentTarget, Long id, EPaymentStatus ePaymentStatus);

    boolean existsByTargetAndReservationIdAndStatus(EPaymentTarget target, Long reservationId, EPaymentStatus status);

    boolean existsByTargetAndOrderIdAndStatus(EPaymentTarget target, Long orderId, EPaymentStatus status);

    @Query("select coalesce(sum(p.amount), 0) from Payment p where p.target = :target and p.reservation.id = :reservationId and p.status = :status")
    BigDecimal sumAmountByTargetAndReservationIdAndStatus(
            @Param("target") EPaymentTarget target,
            @Param("reservationId") Long reservationId,
            @Param("status") EPaymentStatus status
    );
}
