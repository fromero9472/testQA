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
    @DisplayName("CreditProfileCustomer")
    @Story("CreditProfileCustomer")
    @Issue("CreditProfileCustomer")
    @Severity(SeverityLevel.CRITICAL)
    Karate CreditProfileCustomer() {
        return Karate.run("classpath:features/CreditProfileCustomer.feature");
    }
    @Karate.Test
    @DisplayName("PCP-47042")
    @Story("PCP-47042")
    @Issue("PCP-47042")
    @Severity(SeverityLevel.CRITICAL)
    Karate PCP_47042() {
        return Karate.run("classpath:features/PCP-47042.feature");
    }

    @Karate.Test
    @DisplayName("PCP-49054")
    @Story("PCP-49054")
    @Issue("PCP-49054")
    @Severity(SeverityLevel.CRITICAL)
    Karate PCP_49054() {
        return Karate.run("classpath:features/PCP-49054.feature");
    }

    @Karate.Test
    @DisplayName("PCP-54734 - History Credit Profile Batch")
    @Story("PCP-54734")
    @Issue("PCP-54734")
    @Severity(SeverityLevel.NORMAL)
    Karate PCP_54734() {
        return Karate.run("classpath:features/PCP-54734.feature");
    }
}
