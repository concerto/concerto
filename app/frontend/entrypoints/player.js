import { createApp } from 'vue'
import App from '../components/Screen.vue'

const div = document.getElementById('screen');
const apiUrl = div.dataset.apiUrl;

createApp(App, {apiUrl: apiUrl}).mount(div);
