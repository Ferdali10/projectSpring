package tn.esprit.spring.Entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.Set;

@Entity
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Bloc {
    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY)
    @Setter(AccessLevel.NONE)
    Long idBloc;

    String nomBloc;
    Long capaciteBloc;
    @JsonIgnore
    @ManyToOne
    Foyer foyer;
    @JsonIgnore
    @OneToMany(cascade = CascadeType.ALL, mappedBy = "bloc")
    Set<Chambre> chambre;


}
