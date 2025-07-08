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
public class Etudiant {
    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY)
    @Setter(AccessLevel.NONE)
    Long idEtudiant;

    String nomEtudiant;
    String prenomEtudiant;
    Long cin;
    String ecole;
    Date dateNaissance;

    @ManyToMany(cascade = CascadeType.ALL,mappedBy = "etudiants")
    Set<Reservation> reservations;

}
