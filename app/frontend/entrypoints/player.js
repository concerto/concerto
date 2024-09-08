import { createApp } from 'vue'
import App from '../components/ConcertoScreen.vue'

const div = document.getElementById('screen');
const apiUrl = div.dataset.apiUrl;

createApp(App, {apiUrl: apiUrl}).mount(div);
