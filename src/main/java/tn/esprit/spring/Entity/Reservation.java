package tn.esprit.spring.Entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.Date;
import java.util.Set;

@Entity
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Reservation {
    @Id
    @Setter(AccessLevel.NONE)
    String idReservation;

    Date anneeUniversitaire;
    Boolean estValide;

    @ManyToMany(cascade = CascadeType.ALL)
    Set<Etudiant> etudiants;
}
