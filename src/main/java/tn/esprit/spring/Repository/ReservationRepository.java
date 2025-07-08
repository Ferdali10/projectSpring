package tn.esprit.spring.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.esprit.spring.Entity.Reservation;

public interface ReservationRepository extends JpaRepository<Reservation, Long> {
}
