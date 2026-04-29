package karate;

import com.intuit.karate.junit5.Karate;
import io.qameta.allure.Epic;
import io.qameta.allure.Feature;
import io.qameta.allure.Issue;
import io.qameta.allure.Owner;
import io.qameta.allure.Severity;
import io.qameta.allure.SeverityLevel;
import io.qameta.allure.Story;
import org.junit.jupiter.api.DisplayName;

@Epic("ClaroPay Argentina")
@Feature("Credit Profile")
@Owner("QA Automation")
public class KarateRunner {

    @Karate.Test
    @DisplayName("Karate Dynamic Runner")
    @Story("DYNAMIC")
    @Issue("DYNAMIC")
    @Severity(SeverityLevel.CRITICAL)
    Karate runSelectedFeature() {
        return Karate.run().relativeTo(getClass());
    }
}
