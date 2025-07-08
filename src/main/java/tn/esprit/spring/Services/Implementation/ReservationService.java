package tn.esprit.spring.Services.Implementation;

import tn.esprit.spring.Entity.Reservation;
import tn.esprit.spring.Repository.ReservationRepository;
import tn.esprit.spring.Services.Interfaces.IReservationService;

import java.util.List;

public class ReservationService implements IReservationService {
    ReservationRepository reservationRepository;

    @Override
    public List<Reservation> retrieveAllReservation() {
        return reservationRepository.findAll();
    }

    @Override
    public Reservation updateReservation(Reservation res) {
        return reservationRepository.save(res);
    }

    @Override
    public Reservation retrieveReservation(String idReservation) {
        return reservationRepository.findById(Long.valueOf(idReservation)).orElse(null);
    }
}
