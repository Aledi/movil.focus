package com.android.focus.authentication;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.Fragment;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.CompoundButton.OnCheckedChangeListener;
import android.widget.EditText;
import android.widget.RadioButton;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;
import android.widget.Toast;

import com.android.focus.FocusApp;
import com.android.focus.R;
import com.android.focus.managers.UserPreferencesManager;
import com.android.focus.model.User;
import com.android.focus.network.HttpResponseHandler;
import com.android.focus.network.NetworkManager;
import com.android.focus.utils.ArrayDefaultAdapter;
import com.android.focus.utils.BorderTextWatcher;
import com.android.focus.utils.DateUtils;
import com.android.focus.utils.TextUtils;
import com.android.focus.utils.UIUtils;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.loopj.android.http.RequestParams;

import org.json.JSONObject;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.List;

import cz.msebera.android.httpclient.Header;

import static com.android.focus.model.User.APELLIDOS;
import static com.android.focus.model.User.CALLE_NUMERO;
import static com.android.focus.model.User.COLONIA;
import static com.android.focus.model.User.CP;
import static com.android.focus.model.User.EDUCACION;
import static com.android.focus.model.User.EMAIL;
import static com.android.focus.model.User.ESTADO;
import static com.android.focus.model.User.FECHA_NACIMIENTO;
import static com.android.focus.model.User.FEMALE;
import static com.android.focus.model.User.GENERO;
import static com.android.focus.model.User.MALE;
import static com.android.focus.model.User.MUNICIPIO;
import static com.android.focus.model.User.NOMBRE;
import static com.android.focus.model.User.PASSWORD;
import static com.android.focus.network.APIConstants.STATUS;
import static com.android.focus.network.APIConstants.SUCCESS;
import static com.android.focus.network.APIConstants.USERNAME;

public class RegistrationFragment extends Fragment implements OnCheckedChangeListener, OnItemSelectedListener, OnClickListener, OnEditorActionListener {

    private static final String TAG = RegistrationFragment.class.getCanonicalName();
    public static final String FRAGMENT_TAG = TAG + ".registrationFragment";

    private Activity activity;
    private boolean enableBack = true;
    private boolean creatingView = true;
    private RequestParams params;
    private User user;
    private View loader;
    // Username.
    private EditText username;
    private EditText password;
    // Genera Info.
    private EditText firstName;
    private EditText lastName;
    private EditText email;
    private RadioButton male;
    private int day = 0;
    private Spinner daySpinner;
    private int month = 0;
    private Spinner monthSpinner;
    private int year = DateUtils.getMinYear();
    private Spinner yearSpinner;
    private int education;
    private Spinner educationSpinner;
    // Address.
    private ArrayDefaultAdapter cityAdapter;
    private EditText street;
    private EditText streetNum;
    private EditText colonia;
    private EditText zipCode;
    private List<State> states;
    private List<String> cities;
    private List<String> statesText;
    private Spinner citySpinner;
    private Spinner stateSpinner;
    private String city;
    private String state;
    // Button.
    private Button registerUser;

    // region TextWatcher variables
    private TextWatcher usernameTextWatcher = new TextWatcher() {
        @Override
        public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            // Do nothing.
        }

        @Override
        public void onTextChanged(CharSequence s, int start, int before, int count) {
            user.setUsername(s.toString().trim());
        }

        @Override
        public void afterTextChanged(Editable s) {
            setValidBorder(username);
        }
    };

    private TextWatcher emailTextWatcher = new TextWatcher() {
        @Override
        public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            // Do nothing.
        }

        @Override
        public void onTextChanged(CharSequence s, int start, int before, int count) {
            user.setEmail(s.toString().trim());
        }

        @Override
        public void afterTextChanged(Editable s) {
            setValidBorder(email);
        }
    };
    // endregion

    // region Factory methods

    /**
     * Use this factory method to create a new instance of
     * this fragment using the provided parameters.
     *
     * @return A new instance of fragment RegistrationFragment.
     */
    @NonNull
    public static RegistrationFragment newInstance() {
        RegistrationFragment fragment = new RegistrationFragment();
        fragment.setArguments(new Bundle());

        return fragment;
    }
    // endregion

    // region Fragment lifecycle
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        user = new User();
        statesText = new ArrayList<>();
        states = getStates();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        super.onCreateView(inflater, container, savedInstanceState);

        View view = inflater.inflate(R.layout.fragment_registration, container, false);
        loader = view.findViewById(R.id.loader);

        username = (EditText) view.findViewById(R.id.txt_username);
        username.addTextChangedListener(usernameTextWatcher);
        password = (EditText) view.findViewById(R.id.txt_password);
        password.addTextChangedListener(new BorderTextWatcher(password));

        firstName = (EditText) view.findViewById(R.id.txt_first_name);
        firstName.addTextChangedListener(new BorderTextWatcher(firstName));
        lastName = (EditText) view.findViewById(R.id.txt_last_name);
        lastName.addTextChangedListener(new BorderTextWatcher(lastName));
        email = (EditText) view.findViewById(R.id.txt_email);
        email.addTextChangedListener(emailTextWatcher);
        male = (RadioButton) view.findViewById(R.id.btn_male);
        male.setOnCheckedChangeListener(this);
        RadioButton female = (RadioButton) view.findViewById(R.id.btn_female);
        female.setOnCheckedChangeListener(this);
        daySpinner = (Spinner) view.findViewById(R.id.spinner_day);
        daySpinner.setOnItemSelectedListener(this);
        ArrayAdapter<CharSequence> monthAdapter = ArrayAdapter.createFromResource(getActivity(), R.array.month_array, android.R.layout.simple_spinner_item);
        monthAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        monthSpinner = (Spinner) view.findViewById(R.id.spinner_month);
        monthSpinner.setAdapter(monthAdapter);
        monthSpinner.setOnItemSelectedListener(this);
        monthSpinner.setSelection(0);
        ArrayAdapter<String> yearAdapter = new ArrayAdapter<>(getActivity(), android.R.layout.simple_spinner_item, DateUtils.getYears());
        yearAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        yearSpinner = (Spinner) view.findViewById(R.id.spinner_year);
        yearSpinner.setAdapter(yearAdapter);
        yearSpinner.setOnItemSelectedListener(this);
        yearSpinner.setSelection(0);
        ArrayDefaultAdapter educationAdapter = new ArrayDefaultAdapter(getResources().getStringArray(R.array.education_array), getActivity());
        educationAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        educationSpinner = (Spinner) view.findViewById(R.id.spinner_education);
        educationSpinner.setAdapter(educationAdapter);
        educationSpinner.setOnItemSelectedListener(this);

        street = (EditText) view.findViewById(R.id.txt_street);
        street.addTextChangedListener(new BorderTextWatcher(street));
        streetNum = (EditText) view.findViewById(R.id.txt_street_num);
        streetNum.addTextChangedListener(new BorderTextWatcher(streetNum));
        colonia = (EditText) view.findViewById(R.id.txt_colonia);
        colonia.addTextChangedListener(new BorderTextWatcher(colonia));
        ArrayDefaultAdapter stateAdapter = new ArrayDefaultAdapter(statesText, getActivity());
        stateAdapter.setDropDownViewResource(R.layout.simple_spinner_dropdown_item);
        stateSpinner = (Spinner) view.findViewById(R.id.spinner_state);
        stateSpinner.setAdapter(stateAdapter);
        stateSpinner.setOnItemSelectedListener(this);
        stateSpinner.setSelection(0);
        stateSpinner.setFocusable(true);
        stateSpinner.setFocusableInTouchMode(true);
        citySpinner = (Spinner) view.findViewById(R.id.spinner_city);
        citySpinner.setOnItemSelectedListener(this);
        citySpinner.setFocusable(true);
        citySpinner.setFocusableInTouchMode(true);
        zipCode = (EditText) view.findViewById(R.id.txt_zip_code);
        zipCode.addTextChangedListener(new BorderTextWatcher(zipCode));
        zipCode.setOnEditorActionListener(this);

        registerUser = (Button) view.findViewById(R.id.btn_register_user);
        registerUser.setOnClickListener(this);

        return view;
    }

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);

        activity = getActivity();
        UIUtils.hideKeyboardOnFragmentStart(activity);
    }
    // endregion

    // region UI methods
    private void showError(String error) {
        enableBack = true;
        loader.setVisibility(View.GONE);
        Toast.makeText(activity, error, Toast.LENGTH_SHORT).show();
    }

    private void setValidBorder(View view) {
        setBorder(view, R.drawable.border);
    }

    private void setInvalidBorder(View view) {
        setBorder(view, R.drawable.border_invalid);
    }

    private void setBorder(View view, int resourceId) {
        view.setBackgroundResource(resourceId);
    }
    // endregion

    // region Helper methods
    private boolean checkForInvalidFields() {
        boolean invalidFields = false;

        String passwordText = password.getText().toString().trim();
        String firstNameText = firstName.getText().toString().trim();
        String lastNameText = lastName.getText().toString().trim();
        String streetText = street.getText().toString().trim();
        String streetNumText = streetNum.getText().toString().trim();
        String coloniaText = colonia.getText().toString().trim();
        String zipCodeText = zipCode.getText().toString().trim();

        if (!TextUtils.isValidString(user.getUsername())) {
            invalidFields = true;
            setInvalidBorder(username);
        }

        if (!TextUtils.isValidPassword(passwordText)) {
            invalidFields = true;
            setInvalidBorder(password);
        }

        if (!TextUtils.isValidString(firstNameText)) {
            invalidFields = true;
            setInvalidBorder(firstName);
        }

        if (!TextUtils.isValidString(lastNameText)) {
            invalidFields = true;
            setInvalidBorder(lastName);
        }

        user.setNombre(firstNameText + " " + lastNameText);

        if (!TextUtils.isValidEmail(user.getEmail())) {
            invalidFields = true;
            setInvalidBorder(email);
        }

        if (education == 0) {
            invalidFields = true;
            setInvalidBorder(educationSpinner.getChildAt(0));
        }

        if (!TextUtils.isValidString(streetText)) {
            invalidFields = true;
            setInvalidBorder(street);
        }

        if (!TextUtils.isValidString(streetNumText)) {
            invalidFields = true;
            setInvalidBorder(streetNum);
        }

        if (!TextUtils.isValidString(coloniaText)) {
            invalidFields = true;
            setInvalidBorder(colonia);
        }

        if (!TextUtils.isValidString(state)) {
            invalidFields = true;
            setInvalidBorder(stateSpinner.getChildAt(0));
        }

        if (city.equals("Municipio")) {
            invalidFields = true;
            setInvalidBorder(citySpinner.getChildAt(0));
        }

        if (!TextUtils.isValidString(zipCodeText)) {
            invalidFields = true;
            setInvalidBorder(zipCode);
        }

        if (invalidFields) {
            return true;
        }

        params.put(USERNAME, user.getUsername());
        params.put(PASSWORD, passwordText);
        params.put(NOMBRE, firstNameText);
        params.put(APELLIDOS, lastNameText);
        params.put(EMAIL, user.getEmail());
        params.put(GENERO, user.getGenero());
        params.put(FECHA_NACIMIENTO, getBirthDate());
        params.put(EDUCACION, education);
        params.put(CALLE_NUMERO, streetText + " " + streetNumText);
        params.put(COLONIA, coloniaText);
        params.put(ESTADO, state);
        params.put(MUNICIPIO, city);
        params.put(CP, zipCodeText);

        return false;
    }

    private String getBirthDate() {
        String dayString;
        String monthString;

        if (day < 10) {
            dayString = "0" + day;
        } else {
            dayString = Integer.toString(day);
        }

        if (month < 10) {
            monthString = "0" + (month + 1);
        } else {
            monthString = Integer.toString(month + 1);
        }

        return year + "-" + monthString + "-" + dayString;
    }

    private List<State> getStates() {
        InputStream inputStream = FocusApp.getAppResources().openRawResource(R.raw.states);
        Reader reader = new InputStreamReader(inputStream);

        List<State> states = (new Gson()).fromJson(reader, new TypeToken<List<State>>() {
        }.getType());

        for (State state : states) {
            statesText.add(state.getEstado());
        }

        return states;
    }
    // endregion

    // region Listeners
    @Override
    public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
        buttonView.setChecked(isChecked);

        if (isChecked) {
            buttonView.setButtonDrawable(R.drawable.ic_radio_on);
            user.setGenero(buttonView.equals(male) ? MALE : FEMALE);
        } else {
            buttonView.setButtonDrawable(R.drawable.ic_radio_off);
        }
    }

    public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
        if (parent.equals(daySpinner)) {
            day = position + 1;
        } else if (parent.equals(monthSpinner)) {
            month = position;
            updateDaySpinner();
        } else if (parent.equals(yearSpinner)) {
            year = Calendar.getInstance().get(Calendar.YEAR) - 18 - position;
            updateDaySpinner();
        } else if (parent.equals(educationSpinner)) {
            education = position;
        } else if (parent.equals(stateSpinner)) {
            boolean notDefaultValue = position != 0;
            State stateObject = states.get(position);
            state = stateObject.getAbreviacion();
            cities = stateObject.getMunicipios();
            cityAdapter = new ArrayDefaultAdapter(cities, getActivity());
            cityAdapter.setDropDownViewResource(R.layout.simple_spinner_dropdown_item);
            citySpinner.setEnabled(notDefaultValue);
            citySpinner.setClickable(notDefaultValue);
            citySpinner.setAdapter(cityAdapter);

            if (!creatingView) {
                stateSpinner.requestFocus();
            }
        } else if (parent.equals(citySpinner)) {
            city = cities.get(position);

            if (creatingView) {
                creatingView = false;
            } else {
                citySpinner.requestFocus();
            }
        }

        if (position > 0) {
            setValidBorder(parent);
        }
    }

    public void onNothingSelected(AdapterView<?> parent) {
        // Do nothing.
    }

    @Override
    public void onClick(View view) {
        if (view.equals(registerUser)) {
            registerUser();
        }
    }

    @Override
    public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
        if (actionId == EditorInfo.IME_ACTION_DONE || actionId == KeyEvent.KEYCODE_ENTER) {
            registerUser.callOnClick();
        }

        return false;
    }
    // endregion

    // region Click Actions
    private void updateDaySpinner() {
        Calendar calendar = new GregorianCalendar(year, month, 1);
        int numberOfDays = calendar.getActualMaximum(Calendar.DAY_OF_MONTH);
        List<String> days = new ArrayList<>();

        for (int i = 0; i < numberOfDays; i++) {
            days.add(Integer.toString(i + 1));
        }

        daySpinner.setAdapter(getArrayAdapterForList(days));
        daySpinner.setSelection((day <= numberOfDays) ? day - 1 : numberOfDays - 1);
    }

    private ArrayAdapter<String> getArrayAdapterForList(List<String> list) {
        ArrayAdapter<String> adapter = new ArrayAdapter<>(getActivity(), android.R.layout.simple_spinner_item, list);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);

        return adapter;
    }

    public void registerUser() {
        UIUtils.hideKeyboardIfShowing(activity);
        params = new RequestParams();

        if (checkForInvalidFields()) {
            return;
        }

        if (NetworkManager.isNetworkUnavailable(activity)) {
            return;
        }

        loader.setVisibility(View.VISIBLE);
        enableBack = false;

        NetworkManager.registerUser(params, new HttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                if (!response.optString(STATUS).equals(SUCCESS)) {
                    showError(getString(R.string.sign_up_error));
                    return;
                }

                // Save user.
                User.setCurrentUser(user);
                UserPreferencesManager.saveCurrentUser(user);

                // TODO: Register device token.

                // Close any authentication activity before starting welcome activity.
                Intent intent = new Intent(activity, WelcomeActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(intent);
            }

            @Override
            public void onFailure(int statusCode, Header[] headers, String errorResponse, Throwable throwable) {
                showError(errorResponse);
            }
        });
    }

    public void handleOnBackPressedEvent() {
        if (enableBack) {
            activity.finish();
        }
    }
    // endregion

    // region Classes
    private class State {
        private String abreviacion;
        private String estado;
        private List<String> municipios;

        // region Getters and setters
        String getAbreviacion() {
            return abreviacion;
        }

        void setAbreviacion(String abreviacion) {
            this.abreviacion = abreviacion;
        }

        String getEstado() {
            return estado;
        }

        void setEstado(String estado) {
            this.estado = estado;
        }

        List<String> getMunicipios() {
            return municipios;
        }

        void setMunicipios(List<String> municipios) {
            this.municipios = municipios;
        }
        // endregion
    }
    // endregion
}
